# 返回两个对象的宏：

```c
#ifndef RESULT_H
#define RESULT_H

/* ---------- 核心拼接宏 ---------- */
#define __RESULT_CAT(a, b)    a##_##b##_result
#define RESULT_TYPE(T, E)     __RESULT_CAT(T, E)

/* 声明一个“值 + 错误”的结构体类型 */
#define DEF_RESULT(T, E) \
    typedef struct { \
        T value; \
        E error; \
    } RESULT_TYPE(T, E)

/* 函数签名宏：自动生成返回类型 */
#define RESULT_FN(T, E, name, ...) \
    RESULT_TYPE(T, E) name(__VA_ARGS__)

/* 构造返回值 */
#define RESULT_RET(T, E, val, err) \
    ((RESULT_TYPE(T, E)){ .value = (val), .error = (err) })

/* 解包到变量（避免手写 .value / .error） */
#define RESULT_UNPACK(expr, v, e) \
    do { \
        __typeof__(expr) __t = (expr); \
        (v) = __t.value; \
        (e) = __t.error; \
    } while (0)

/* 只读错误码 */
#define RESULT_ERR(expr) \
    ({ __typeof__(expr) __t = (expr); __t.error; })

#endif /* RESULT_H */
```

---

### 使用示例

```c
#include "result.h"

/* 复杂类型先 typedef 成单 token */
typedef unsigned int uint;

/* 声明类型：uint + int 错误码 → 生成 uint_int_result */
DEF_RESULT(uint, int);

/* 函数签名展开为 uint_int_result divide(...) */
RESULT_FN(uint, int, divide, uint a, uint b)
{
    if (b == 0)
        return RESULT_RET(uint, int, 0, -1);
    return RESULT_RET(uint, int, a / b, 0);
}

int main(void)
{
    uint val;
    int  err;
    RESULT_UNPACK(divide(10, 0), val, err);   /* val = 0, err = -1 */

    /* 或者直接访问字段 */
    uint val2 = divide(10, 2).value;
    int  err2 = RESULT_ERR(divide(10, 2));

    (void)val; (void)err; (void)val2; (void)err2;
    return 0;
}
```

---

### 宏展开后的实际代码

```c
typedef struct {
    uint value;
    int  error;
} uint_int_result;

uint_int_result divide(uint a, uint b)
{
    if (b == 0)
        return ((uint_int_result){ .value = (0), .error = (-1) });
    return ((uint_int_result){ .value = (a / b), .error = (0) });
}
```

---

### 命名速查

| 宏 | 作用 |
|---|---|
| `DEF_RESULT(T, E)` | 定义 `T_E_result` 结构体 |
| `RESULT_TYPE(T, E)` | 获取生成的结构体类型名 |
| `RESULT_FN(T, E, name, ...)` | 定义返回该结构体的函数 |
| `RESULT_RET(T, E, val, err)` | 构造返回值 |
| `RESULT_UNPACK(expr, v, e)` | 解包到两个变量 |
| `RESULT_ERR(expr)` | 只取错误码 |

单 token 约束不变：`T` 和 `E` 都必须是单个标识符，多单词类型请先 `typedef`。
