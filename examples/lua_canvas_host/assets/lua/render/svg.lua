-- render/svg.lua
--
-- 把显示列表转成 SVG。
-- 这不是生产用途，而是验证"显示列表是纯数据"这个论点：
-- 同一份 Lua 场景图，可以脱离 Flutter 输出到任意后端。

local function esc(s)
  return (s:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

-- 文本节点转义：还要处理引号，否则会破坏属性边界。
local function esc_text(s)
  local r = esc(s)
  return (r:gsub('"', "&quot;"))
end

local function color(c, fallback)
  return c or fallback
end

local function to_svg(list)
  local out = {}
  local W, H = list.width, list.height

  out[#out + 1] = string.format(
    '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">',
    W, H, W, H)
  out[#out + 1] = string.format('<rect width="%d" height="%d" fill="%s"/>',
    W, H, list.background)

  for _, op in ipairs(list.ops) do
    if op.op == "circle" then
      if op.fill then
        out[#out + 1] = string.format('<circle cx="%s" cy="%s" r="%s" fill="%s"/>',
          op.x, op.y, op.r, op.fill)
      end
      if op.stroke then
        out[#out + 1] = string.format('<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="%s"/>',
          op.x, op.y, op.r, op.stroke, op.stroke_width)
      end

    elseif op.op == "rect" then
      local rx = op.radius and op.radius > 0
        and string.format(' rx="%s"', op.radius) or ""
      out[#out + 1] = string.format(
        '<rect x="%s" y="%s" width="%s" height="%s"%s fill="%s" stroke="%s" stroke-width="%s"/>',
        op.x, op.y, op.w, op.h, rx,
        color(op.fill, "none"), color(op.stroke, "none"), op.stroke_width)

    elseif op.op == "line" then
      out[#out + 1] = string.format(
        '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        op.x1, op.y1, op.x2, op.y2, color(op.stroke, "#fff"), op.stroke_width)

    elseif op.op == "text" then
      local anchor = op.align == "right" and ' text-anchor="end"'
        or (op.align == "center" and ' text-anchor="middle"' or "")
      out[#out + 1] = string.format(
        '<text x="%s" y="%s" fill="%s" font-size="%s"%s>%s</text>',
        op.x, op.y, color(op.color, "#fff"), op.size, anchor, esc_text(op.text))

    elseif op.op == "polygon" and op.points and #op.points >= 2 then
      local pts = {}
      for _, p in ipairs(op.points) do
        pts[#pts + 1] = string.format("%s,%s", p.x, p.y)
      end
      out[#out + 1] = string.format(
        '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>',
        table.concat(pts, " "), color(op.stroke, "#fff"), op.stroke_width)
    end
  end

  out[#out + 1] = "</svg>"
  return table.concat(out, "\n")
end

return { to_svg = to_svg }