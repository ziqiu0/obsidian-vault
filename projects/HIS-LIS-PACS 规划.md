---
created: 2026-04-22
tags: #项目, #医疗, #规划
status: 规划完成
path: ~/.hermes/plans/
---

# HIS-LIS-PACS 规划

> 医院信息系统 (HIS) + 实验室信息系统 (LIS) + 影像系统 (PACS) 整体规划
> 目标: 二甲～三甲综合医院

## 规划文档

| 文档 | 行数 | 状态 |
|------|------|------|
| 架构规划 | 565 | ✅ |
| 功能模块规划 (HIS 14 + LIS 10 + PACS 10 模块) | 733 | ✅ |
| 数据库设计 (~130+ 表, 含等保2.0) | 3607 | ✅ |
| 技术架构 v1.1 | 1178 | ✅ |
| 接口协议设计 (INT-001~INT-010) | 780 | ✅ |

## 核心技术选型

- **集成引擎:** Apache Camel + Spring Boot
- **数据库:** PostgreSQL (JSONB for FHIR)
- **消息队列:** Apache Kafka
- **缓存:** Redis Cluster
- **PACS:** Orthanc + DCM4CHEE
- **容器:** Kubernetes

## 实施进展

规划全部完成 → 已进入实施阶段

→ 详见 [[Hospital Integration Engine]]

## 关联

- [[Hospital Integration Engine]] — 落地实施
- [[HIS/LIS/PACS 数据库设计]] — 130+ 表设计
- [[HIS/LIS/PACS 接口协议]] — 10 个接口规范
