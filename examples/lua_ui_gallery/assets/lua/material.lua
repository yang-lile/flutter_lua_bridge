-- Material widgets. Gallery.showSnackBar and Gallery.fetchQuote are Dart
-- functions of the app (lib/gallery.dart); fetchQuote returns a Future,
-- and the handler continues when it completes.
local shades = { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900 }

local function section(title, children)
  return Card {
    margin = EdgeInsets.only { bottom = 12 },
    child = Padding {
      padding = EdgeInsets.all(16),
      child = Column {
        crossAxisAlignment = CrossAxisAlignment.start,
        spacing = 8,
        children = {
          Text { title, style = TextStyle { fontSize = 16, fontWeight = FontWeight.w600 } },
          Wrap { spacing = 8, runSpacing = 8, crossAxisAlignment = WrapCrossAlignment.center, children = children },
        },
      },
    },
  }
end

return App {
  store = {
    presses = 0, wifi = true, agree = false, volume = 0.3,
    draft = "", tags = { "Lua", "Flutter" }, quote = "", loading = false,
  },
  view = function(store)
    local chips = {}
    for i, tag in ipairs(store.tags) do
      chips[#chips + 1] = Chip {
        key = tag,
        label = Text { tag },
        onDeleted = function() table.remove(store.tags, i) end,
      }
    end
    local swatch = {}
    for _, shade in ipairs(shades) do
      swatch[#swatch + 1] = Container { width = 28, height = 28, color = Colors.indigo[shade] }
    end
    local function press() store.presses = store.presses + 1 end

    return Scaffold {
      appBar = AppBar {
        title = Text { "Material" },
        actions = {
          IconButton {
            icon = Icon { Icons.refresh },
            tooltip = "重置",
            onPressed = function()
              store.presses = 0
              Gallery.showSnackBar("计数已重置")
            end,
          },
        },
      },
      floatingActionButton = FloatingActionButton.extended {
        icon = Icon { Icons.check },
        label = Text { "完成" },
        onPressed = function() Navigator.pop("按了 " .. store.presses .. " 次") end,
      },
      body = ListView {
        padding = EdgeInsets.all(12),
        children = {
          section("按钮：按了 " .. store.presses .. " 次", {
            ElevatedButton { onPressed = press, child = Text { "Elevated" } },
            FilledButton { onPressed = press, child = Text { "Filled" } },
            FilledButton.tonal { onPressed = press, child = Text { "Tonal" } },
            OutlinedButton { onPressed = press, child = Text { "Outlined" } },
            TextButton { onPressed = press, child = Text { "Text" } },
            IconButton.filled { icon = Icon { Icons.add }, onPressed = press },
          }),
          section("开关与滑块", {
            SizedBox { width = 360, child = Column { children = {
              ListTile {
                title = Text { "Wi-Fi" },
                subtitle = Text { store.wifi and "已打开" or "已关闭" },
                trailing = Switch { value = store.wifi, onChanged = function(v) store.wifi = v end },
              },
              ListTile {
                title = Text { "同意条款" },
                leading = Checkbox { value = store.agree, onChanged = function(v) store.agree = v end },
              },
              Slider {
                value = store.volume, divisions = 10,
                label = math.floor(store.volume * 100 + 0.5) .. "%",
                onChanged = function(v) store.volume = v end,
              },
              LinearProgressIndicator { value = store.volume },
            } } },
          }),
          section("输入框：回车加一个标签", {
            SizedBox { width = 360, child = TextField {
              text = store.draft,
              decoration = InputDecoration {
                labelText = "标签", hintText = "输入后按回车",
                border = OutlineInputBorder {},
              },
              onChanged = function(v) store.draft = v end,
              onSubmitted = function(v)
                if v ~= "" then table.insert(store.tags, v) end
                store.draft = ""
              end,
            } },
            table.unpack(chips),
          }),
          section("调用 Dart 的异步函数", {
            FilledButton.icon {
              icon = Icon { Icons.send },
              label = Text { "取一句话" },
              onPressed = function()
                store.loading = true
                store.quote = Gallery.fetchQuote(store.presses)
                store.loading = false
              end,
            },
            store.loading and CircularProgressIndicator { strokeWidth = 2 } or Text { store.quote },
          }),
          section("Colors.indigo[50…900]", swatch),
        },
      },
    }
  end,
}
