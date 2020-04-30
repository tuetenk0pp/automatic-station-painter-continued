**Automatic Station Painter** updates the colors of train stations based on the color of the trains. It works best with **[Automatic Train Painter](https://mods.factorio.com/mod/Automatic_Train_Painter)**, though it isn't required.

The painting logic follows:

- if the train arrives and leaves empty, it does not paint the station;
- if the train is empty when it leaves the station, it uses the train's color from when it arrived;
- otherwise it uses the train's color when it leaves the station.

The mod has a map setting--the color blend ratio--that allows you to control how quickly the station's color converges to that of the train.

_Thumbnail created by [yeahtoast](https://mods.factorio.com/user/yeahtoast)_.