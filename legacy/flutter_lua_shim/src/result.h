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
