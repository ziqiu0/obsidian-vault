---
created: 2026-04-22
tags: #项目, #医疗, #集成引擎
status: 实施中
tech_stack: Spring Boot 3.3, Camel 4.4, Kafka, PostgreSQL, Redis
path: ~/projects/hospital-integration/
---

# Hospital Integration Engine

> HIS / LIS / PACS 系统间接口集成引擎
> [[HIS-LIS-PACS 规划]] 的落地实施产物

## 概况

- **技术栈:** Spring Boot 3.3 + Camel 4.4 + Kafka + PostgreSQL + Redis
- **端口:** 8080
- **Docker 中间件:** hospital-postgres, hospital-kafka, hospital-zookeeper, hospital-redis
- **进度:** ~30-40%

## 已完成

- ✅ 多模块项目框架 (integration-common + integration-engine)
- ✅ Kafka 路由: HIS↔LIS 双向 (ADT/ORM/ORU/危急值)
- ✅ HL7 消息解析 → Canonical DTO 转换
- ✅ 消息校验、死信队列、追踪、危急值处理
- ✅ Docker Compose 中间件编排
- ✅ 8080 端口成功启动

## 待做

- [ ] `adapter/PacsDicomAdapter.java` — PACS DICOM 适配器
- [ ] `route/MedicalInsuranceRoute.java` — 医保接口路由 (INT-008)
- [ ] `route/RegionalPlatformRoute.java` — 区域平台路由 (INT-009)
- [ ] `processor/FhirConverterProcessor.java` — FHIR 转换
- [ ] Flyway 数据库迁移脚本
- [ ] 单元测试

## 接口映射

| Kafka Topic | 源→目标 | 接口编号 |
|-------------|---------|---------|
| his-adt-lis | HIS→LIS | INT-001 |
| his-order-lis | HIS→LIS | INT-002 |
| lis-result-his | LIS→HIS | INT-003 |
| lis-critical-his | LIS→HIS | INT-003 危急值 |
| his-order-pacs | HIS→PACS | INT-004 |
| pacs-report-his | PACS→HIS | INT-005 |
| pacs-workflow | HIS↔PACS | INT-006 |
| lis-pacs-join | LIS↔PACS | INT-007 |
| medical-insurance | HIS↔医保 | INT-008 |
| regional-platform | HIS↔区域 | INT-009 |
| audit-event-cdr | All→CDR | INT-010 |

## 相关对话

- [[2026-04-22/11-06_项目总览与Obsidian记录规范]]
- [[2026-04-15 项目调试与启动]]

## 关联

- [[HIS-LIS-PACS 规划]] — 设计蓝图
- [[HIS/LIS/PACS 数据库设计]] — 数据库方案
- [[HIS/LIS/PACS 接口协议]] — 接口规范
