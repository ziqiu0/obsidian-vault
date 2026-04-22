---
uid: API接口汇总
created: 2026-04-22
tags: [api, documentation]
related:
  - "[[../B2B供应商供货系统]]"
  - "[[认证接口 (Auth)]]"
  - "[[商品接口 (Product)]]"
  - "[[购物车接口 (Cart)]]"
  - "[[订单接口 (Order)]]"
  - "[[采购需求接口 (ProductDemand)]]"
  - "[[供货报价接口 (SupplyOffer)]]"
  - "[[供货订单接口 (SupplyOrder)]]"
---

# API 接口汇总

基础路径: `http://localhost:3100/api`

所有接口统一返回格式：

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

| 模块 | 说明 | 链接 |
|------|------|------|
| 认证 | 用户登录注册、个人信息 | [[认证接口 (Auth)]] |
| 商品 | 商品列表、详情 | [[商品接口 (Product)]] |
| 购物车 | 购物车增删改查 | [[购物车接口 (Cart)]] |
| 零售订单 | B2C订单创建查询 | [[订单接口 (Order)]] |
| 采购需求 | B2B采购需求管理 | [[采购需求接口 (ProductDemand)]] |
| 供货报价 | 供应商报价管理 | [[供货报价接口 (SupplyOffer)]] |
| 供货订单 | B2B供货订单管理 | [[供货订单接口 (SupplyOrder)]] |

## 认证方式

需要认证的接口在请求头中携带：

```
Authorization: Bearer {jwt_token}
```

认证失败返回：

```json
{
  "code": 401,
  "message": "认证失败"
}
```

## 权限控制

部分接口需要特定角色：

| 接口 | 需要角色 |
|------|----------|
| 发布/管理采购需求 | admin / procurement |
| 审核报价 | admin / procurement |
| 查看所有用户 | admin |
| 提交报价 | supplier |
| 供应商发货 | supplier |

## 相关链接

- [[认证接口 (Auth)]]
- [[商品接口 (Product)]]
- [[购物车接口 (Cart)]]
- [[订单接口 (Order)]]
- [[采购需求接口 (ProductDemand)]]
- [[供货报价接口 (SupplyOffer)]]
- [[供货订单接口 (SupplyOrder)]]
