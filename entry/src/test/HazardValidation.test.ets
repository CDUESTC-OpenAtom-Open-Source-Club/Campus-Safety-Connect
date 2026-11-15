import { describe, it, beforeEach, expect } from '@ohos/hypium';

import { SecurityEvent, EventPriority, EventType } from '../main/ets/model/SecurityEvent';

import { MemoryEventStore } from '../main/ets/repository/store/MemoryEventStore';

import { EventRepository } from '../main/ets/repository/EventRepository';

import { EventWorkflowService } from '../main/ets/service/EventWorkflowService';

import { AccountService } from '../main/ets/service/AccountService';

import { TEST_STUDENT } from './TestAuthFixture';

/**
 * #15 隐患上报枚举校验回归：
 * reportHazard 必须在落库前拦截非法 type / priority，避免脏值进入 security_event 表。
 */
export default function hazardValidationTest() {
  describe('HazardValidationTest', () => {
    beforeEach(() => {
      AccountService.setCurrentUserForTest(TEST_STUDENT);
      EventRepository.initForTest(new MemoryEventStore());
    });

    it('hazard_report_rejects_invalid_type_and_persists_nothing', 0, () => {
      const repo = EventRepository.getInstance();
      // 模拟 AI 工具链 / 直接调用可能产出的脏值：拼错、小写、带空格、空串
      const badTypes: EventType[] = [
        'BAD' as EventType,
        'fire' as EventType,
        '消防安全 ' as EventType,
        ' ' as EventType
      ];
      for (let i = 0; i < badTypes.length; i++) {
        const rejected: SecurityEvent | undefined = EventWorkflowService.reportHazard({
          title: '非法类型上报' + i.toString(),
          type: badTypes[i],
          location: '教学楼一层',
          description: '模拟模型输出脏值'
        });
        expect(rejected === undefined).assertTrue();
      }
      expect(repo.getEvents().length).assertEqual(0);
    });

    it('hazard_report_rejects_invalid_priority_and_persists_nothing', 0, () => {
      const repo = EventRepository.getInstance();
      const badPriorities: EventPriority[] = [
        'BAD' as EventPriority,
        'urgent' as EventPriority,
        '紧急 ' as EventPriority,
        '' as EventPriority
      ];
      for (let i = 0; i < badPriorities.length; i++) {
        const rejected: SecurityEvent | undefined = EventWorkflowService.reportHazard({
          title: '非法优先级上报' + i.toString(),
          type: EventType.FIRE,
          location: '实验楼二层',
          description: '模拟模型输出脏值',
          priority: badPriorities[i]
        });
        expect(rejected === undefined).assertTrue();
      }
      expect(repo.getEvents().length).assertEqual(0);
    });

    it('hazard_report_accepts_every_whitelisted_type', 0, () => {
      const repo = EventRepository.getInstance();
      const validTypes: EventType[] = [
        EventType.FIRE,
        EventType.ELECTRIC,
        EventType.FACILITY,
        EventType.CAMPUS,
        EventType.OTHER
      ];
      for (let i = 0; i < validTypes.length; i++) {
        const event: SecurityEvent | undefined = EventWorkflowService.reportHazard({
          title: '合法类型' + i.toString(),
          type: validTypes[i],
          location: '实验楼',
          description: '合法枚举值应正常入库'
        });
        expect(event === undefined).assertFalse();
        if (event !== undefined) {
          expect(event.type).assertEqual(validTypes[i]);
        }
      }
      expect(repo.getEvents().length).assertEqual(validTypes.length);
    });

    it('hazard_report_accepts_every_whitelisted_priority', 0, () => {
      const repo = EventRepository.getInstance();
      const validPriorities: EventPriority[] = [
        EventPriority.LOW,
        EventPriority.MEDIUM,
        EventPriority.HIGH,
        EventPriority.URGENT
      ];
      for (let i = 0; i < validPriorities.length; i++) {
        const event: SecurityEvent | undefined = EventWorkflowService.reportHazard({
          title: '合法优先级' + i.toString(),
          type: EventType.FACILITY,
          location: '食堂',
          description: '合法优先级应原样保留',
          priority: validPriorities[i]
        });
        expect(event === undefined).assertFalse();
        if (event !== undefined) {
          expect(event.priority).assertEqual(validPriorities[i]);
        }
      }
      expect(repo.getEvents().length).assertEqual(validPriorities.length);
    });

    it('hazard_report_defaults_priority_to_medium_when_omitted', 0, () => {
      const event: SecurityEvent | undefined = EventWorkflowService.reportHazard({
        title: '未填写优先级',
        type: EventType.OTHER,
        location: '操场',
        description: '缺省优先级按中等级别处理'
      });
      expect(event === undefined).assertFalse();
      if (event !== undefined) {
        expect(event.priority).assertEqual(EventPriority.MEDIUM);
      }
    });
  });
}
