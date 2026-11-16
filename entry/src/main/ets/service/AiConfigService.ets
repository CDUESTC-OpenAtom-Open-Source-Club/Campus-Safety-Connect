import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AiProviderPresets } from './AiProviderPresets';

export interface AiConfig { endpoint: string; model: string; apiKey: string; }

/** One atomic encrypted asset per account; never write API keys to Preferences. */
export class AiConfigService {
  private static sessionOwner: string = '';
  private static sessionConfig: AiConfig | null = null;
  private static generation: number = 0;

  static clearSession(): void {
    AiConfigService.generation++;
    AiConfigService.sessionOwner = ''; AiConfigService.sessionConfig = null;
  }

  static validate(config: AiConfig): string {
    if (typeof config.endpoint !== 'string' ||
      !/^https:\/\/[a-zA-Z0-9.-]+(?::\d{1,5})?\/(?:[a-zA-Z0-9_./~-]+\/)?chat\/completions$/.test(config.endpoint)) {
      return '请填写 HTTPS 的完整 chat/completions 地址，不含查询参数或账号信息';
    }
    if (config.endpoint.length > 300 || config.endpoint.includes('/../') || config.endpoint.includes('/./')) return '服务地址过长或路径无效';
    const authorityError: string = AiConfigService.authorityError(config.endpoint);
    if (authorityError !== '') return authorityError;
    if (typeof config.model !== 'string' || !/^[a-zA-Z0-9_.:/-]{1,100}$/.test(config.model)) return '请填写有效模型 ID（最多 100 字符）';
    if (typeof config.apiKey !== 'string' || config.apiKey.length < 1 || config.apiKey.length > 512 || /\s/.test(config.apiKey)) {
      return '请填写有效 API Key（最多 512 字符，不含空白）';
    }
    return '';
  }

  /** Official presets are trusted built-ins; custom addresses must use a public host and a valid port. */
  private static authorityError(endpoint: string): string {
    if (AiProviderPresets.isOfficial(endpoint)) return '';
    const authority: string = endpoint.substring('https://'.length).split('/')[0];
    const separator: number = authority.lastIndexOf(':');
    const host: string = separator < 0 ? authority : authority.substring(0, separator);
    const port: string = separator < 0 ? '' : authority.substring(separator + 1);
    if (port !== '') {
      const value: number = parseInt(port, 10);
      if (!/^\d{1,5}$/.test(port) || value < 1 || value > 65535) return '服务地址端口无效：端口必须在 1-65535 之间';
    }
    return AiConfigService.hostError(host);
  }

  private static hostError(host: string): string {
    const name: string = host.toLowerCase();
    if (name.length === 0 || name.startsWith('.') || name.endsWith('.') || name.includes('..')) return '服务地址的主机格式无效';
    if (name === 'localhost' || name.endsWith('.localhost') || name === '::1' || name === '[::1]') {
      return '服务地址不能使用 localhost 或本机回环地址';
    }
    if (/^[0-9.]+$/.test(name)) {
      const quad: RegExpMatchArray | null = name.match(/^(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})$/);
      if (quad === null) return '服务地址的主机格式无效';
      const first: number = parseInt(quad[1], 10); const second: number = parseInt(quad[2], 10);
      const third: number = parseInt(quad[3], 10); const fourth: number = parseInt(quad[4], 10);
      if (first > 255 || second > 255 || third > 255 || fourth > 255) return '服务地址的主机格式无效';
      if (first === 127) return '服务地址不能使用 localhost 或本机回环地址';
      if (first === 0) return '服务地址不能使用 0.0.0.0 等保留地址';
      if (first === 10 || (first === 172 && second >= 16 && second <= 31) ||
        (first === 192 && second === 168) || (first === 169 && second === 254)) {
        return '服务地址不能使用内网或保留地址';
      }
    }
    return '';
  }

  static retainedKey(endpoint: string, saved: AiConfig | null): string {
    return saved !== null && saved.endpoint === endpoint ? saved.apiKey : '';
  }

  private static queryFor(owner: string): asset.AssetMap {
    if (!/^[a-zA-Z0-9_-]{1,100}$/.test(owner)) throw new Error('请先登录 App 账号');
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, new util.TextEncoder().encodeInto('campus_ai_' + owner));
    return query;
  }

  static async load(context: common.Context, owner: string): Promise<AiConfig | null> {
    const pref = await preferences.getPreferences(context, 'ai_auth_preferences');
    await pref.delete('ai_access_token'); await pref.flush();
    if (AiConfigService.sessionOwner === owner && AiConfigService.sessionConfig !== null) return AiConfigService.sessionConfig;
    if (!canIUse('SystemCapability.Security.Asset')) return null;
    const query: asset.AssetMap = AiConfigService.queryFor(owner);
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    let items: asset.AssetMap[];
    try { items = await asset.query(query); }
    catch (error) {
      if ((error as BusinessError).code === 24000002) return null;
      throw new Error('安全存储不可用或已锁定；可选择“仅本次使用”');
    }
    if (items.length === 0) return null;
    const secret = items[0].get(asset.Tag.SECRET);
    if (!(secret instanceof Uint8Array)) throw new Error('保存的配置无法读取，请清除后重新配置');
    const config = JSON.parse(new util.TextDecoder().decodeToString(secret)) as AiConfig;
    if (AiConfigService.validate(config) !== '') throw new Error('保存的配置无效，请重新配置');
    return config;
  }

  static async save(owner: string, config: AiConfig, remember: boolean): Promise<void> {
    const generation: number = AiConfigService.generation;
    const validation: string = AiConfigService.validate(config);
    if (validation !== '') throw new Error(validation);
    const query: asset.AssetMap = AiConfigService.queryFor(owner);
    if (remember) {
      if (!canIUse('SystemCapability.Security.Asset')) throw new Error('当前设备不支持安全存储，请选择仅本次使用');
      const bytes: Uint8Array = new util.TextEncoder().encodeInto(JSON.stringify(config));
      if (bytes.length > 1024) throw new Error('配置总长度超出安全存储限制，请缩短地址或模型 ID');
      query.set(asset.Tag.SECRET, bytes);
      query.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_UNLOCKED);
      query.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
      query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
      await asset.add(query);
    } else {
      await AiConfigService.remove(owner, false);
    }
    if (generation !== AiConfigService.generation) return;
    AiConfigService.sessionOwner = owner;
    AiConfigService.sessionConfig = { endpoint: config.endpoint, model: config.model, apiKey: config.apiKey };
  }

  static async remove(owner: string, clearSession: boolean = true): Promise<void> {
    const query: asset.AssetMap = AiConfigService.queryFor(owner);
    try { if (canIUse('SystemCapability.Security.Asset')) await asset.remove(query); }
    catch (error) {
      if ((error as BusinessError).code !== 24000002) throw new Error('无法清除安全存储，请解锁设备后重试');
    }
    if (clearSession && AiConfigService.sessionOwner === owner) AiConfigService.clearSession();
  }
}
