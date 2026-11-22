-- Cupertino widgets. The navigation bar shows the back button because the
-- route can pop; the filled button pops with a result instead.
local segments = {
  { value = "day", child = Text { "日" } },
  { value = "week", child = Text { "周" } },
  { value = "month", child = Text { "月" } },
}
local labels = { day = "按日", week = "按周", month = "按月" }

return App {
  store = { bluetooth = false, brightness = 0.6, period = "week", name = "" },
  view = function(store)
    return CupertinoPageScaffold {
      navigationBar = CupertinoNavigationBar {
        middle = Text { "Cupertino" },
        previousPageTitle = "Gallery",
      },
      child = SafeArea { child = ListView { children = {
        CupertinoListSection.insetGrouped {
          header = Text { "设置" },
          children = {
            CupertinoListTile {
              title = Text { "蓝牙" },
              additionalInfo = Text { store.bluetooth and "开" or "关" },
              trailing = CupertinoSwitch {
                value = store.bluetooth,
                onChanged = function(v) store.bluetooth = v end,
              },
            },
            CupertinoListTile {
              title = Text { "亮度" },
              additionalInfo = Text { math.floor(store.brightness * 100 + 0.5) .. "%" },
            },
            CupertinoListTile {
              title = Text { "统计周期" },
              additionalInfo = Text { labels[store.period] },
            },
          },
        },
        Padding {
          padding = EdgeInsets.symmetric { horizontal = 20 },
          child = Column { spacing = 16, children = {
            CupertinoSlider {
              value = store.brightness,
              onChanged = function(v) store.brightness = v end,
            },
            CupertinoSegmentedControl {
              children = segments,
              groupValue = store.period,
              onValueChanged = function(v) store.period = v end,
            },
            CupertinoTextField {
              placeholder = "你的名字",
              text = store.name,
              onChanged = function(v) store.name = v end,
            },
            Text { store.name == "" and "还没有输入名字" or ("你好，" .. store.name) },
            Row { mainAxisAlignment = MainAxisAlignment.center, spacing = 12, children = {
              CupertinoActivityIndicator {},
              CupertinoButton.filled {
                onPressed = function()
                  Navigator.pop(store.name == "" and "cupertino" or store.name)
                end,
                child = Text { "返回并带回名字" },
              },
            } },
          } },
        },
      } } },
    }
  end,
}
