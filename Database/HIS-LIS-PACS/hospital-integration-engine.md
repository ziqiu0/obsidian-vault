# Hospital Integration Engine - 医院数据交换集成引擎

> 基于 Apache Camel 4.4 + Spring Boot 3.3 的医院信息集成引擎，支持 HL7 v2 消息解析、路由、转换。

## 项目信息

- **路径**: `~/projects/hospital-integration/`
- **启动端口**: `8080`
- **技术栈**: Spring Boot 3.3 + Apache Camel 4.4 + Kafka + PostgreSQL + Redis + Flyway
- **Docker 中间件**: `hospital-postgres`, `hospital-kafka`, `hospital-zookeeper`, `hospital-redis`
- **状态**: ✅ 可正常编译启动，所有 10 个接口路由已实现

## 架构

### 模块结构

```
hospital-integration/
├── integration-common/          # 共享 DTO、常量、工具类
├── integration-engine/          # 核心路由与处理器
│   ├── src/main/java/
│   │   └── com/hospital/integration/engine/
│   │       ├── config/          # Camel 配置、Spring 配置
│   │       ├── route/           # 路由定义 (INT-001 ~ INT-010)
│   │       ├── processor/       # 处理器 (验证、追踪、转换、DLQ...)
│   │       ├── notification/processor/  # 危急值通知处理器
│   │       └── IntegrationEngineApplication.java
│   └── src/main/resources/db/migration/  # Flyway 迁移脚本
└── pom.xml
```

### 已实现的 10 个标准接口

| ID | 接口名称 | 方向 | 状态 |
|----|---------|------|------|
| **INT-001** | HIS → LIS 医嘱预约 | HIS → LIS | ✅ 完成 |
| **INT-002** | LIS → HIS 检验结果报告 | LIS → HIS | ✅ 完成 |
| **INT-003** | HIS → PACS 检查预约 | HIS → PACS | ✅ 完成 |
| **INT-004** | PACS → HIS 检查报告 | PACS → HIS | ✅ 完成 |
| **INT-005** | HIS ↔ EMR 患者主索引同步 | HIS ↔ EMR | ✅ 完成 |
| **INT-006** | HIS → 医保 费用结算 | HIS → Insurance | ✅ 完成 |
| **INT-007** | LIS → PACS 标本信息共享 | LIS → PACS | ✅ 完成 |
| **INT-008** | CDC 传染病报告 | HIS → CDC | ✅ 完成 |
| **INT-009** | 区域健康平台数据上传 | Hospital → Regional | ✅ 完成 |
| **INT-010** | 心电设备数据采集 | ECG → HIS | ✅ 完成 |

## 核心处理器

| 处理器 | 功能 |
|--------|------|
| `ValidationProcessor` | 验证 HL7 消息完整性和必填段 |
| `TracingProcessor` | 生成/传播 trace_id，记录路由时间戳 |
| `Hl7ToCanonicalProcessor` | HL7 v2 → 规范 Canonical DTO 转换 |
| `CanonicalToHl7Processor` | 规范 DTO → HL7 v2 转换 |
| `CriticalValueProcessor` | 危急值检测 |
| `CriticalValueNotificationProcessor` | 危急值通知流程处理 |
| `DeadLetterProcessor` | 死信处理，失败消息路由到 DLQ |
| `KafkaProducerProcessor` | 发送到 Kafka 目标 Topic |

## 数据库设计 (Flyway)

| 版本 | 内容 |
|------|------|
| V1 | 基础 schema，患者主索引，接口日志 |
| V2 | 扩展 schema，医嘱、标本等表 |
| V2_1 (V3) | 安全配置表 (等保 2.0) - API key、IP 白名单、审计日志 |
| V4 | PACS 集成表 (DICOM 研究、序列、实例) |
| V5 | 放射报告表 (危急值关键词字典) |
| V6 | 危急值通知表 (危急值字典、通知联系人、 escalate 规则) |
| V7 | 数据仓库星型模型 (患者维、时间维、科室维、供应商维... 事实表) |

## 单元测试

- **总计**: 50 个测试用例
- **通过**: 43 个
- **跳过**: 7 个（部分测试基于旧的占位实现，后续补全）

## 启动方式

```bash
# 编译
cd ~/projects/hospital-integration
sg docker -c 'docker run --rm -v $(pwd):/app -w /app -v ~/.m2:/root/.m2 --network hospital-net --add-host=host.docker.internal:host-gateway maven:3.9-eclipse-temurin-21 mvn clean package -DskipTests'

# 启动
sg docker -c 'docker run --rm -p 8080:8080 --network hospital-net --add-host=host.docker.internal:host-gateway -v $(pwd):/app -w /app -v ~/.m2:/root/.m2 maven:3.9-eclipse-temurin-21 java -jar integration-engine/target/integration-engine-1.0.0-SNAPSHOT.jar'
```

## 已知问题与修复记录

### 2026-04-22 修复记录

1. **两个 CriticalValueProcessor 冲突** → 重命名通知包中的为 `CriticalValueNotificationProcessor` ✅
2. **Flyway 版本号冲突** → 两个 V2，重新编号为 V1~V7 ✅
3. **外键类型不匹配** → `patient_id` VARCHAR(100) → BIGINT 匹配 `pat_master_index` ✅
4. **ON CONFLICT 语法错误** → 缺失 UNIQUE 约束，添加后修复 ✅
5. **PL/pgSQL DO 块 Flyway 解析错误** → 移除预生成 time_dim 代码，后续增量填充 ✅

## 下一步待做

- [ ] 添加更多单元测试（剩余 7 个）
- [ ] 完成 PACS DICOM 适配器
- [ ] 医保路由规则完善
- [ ] 添加端到端集成测试
- [ ] Flyway 校验

## 链接

- 接口协议设计: [[his-lis-pacs-interface-protocol]]
- 数据库设计: [[his-lis-pacs-database-design]]
- 功能模块规划: [[his-lis-pacs-modules-plan]]
