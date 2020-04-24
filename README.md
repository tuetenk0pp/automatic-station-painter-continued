
**Automatic Station Painter** updates the colors of train stations based on the color of the trains. It works best with **Automatic Train Painter**, though it isn't required.

The painting logic follows:
- if the train arrives and leaves empty, it does not paint the station;
- if the train is empty when it leaves the station, it uses the train's color when it arrived;
- otherwise it uses the train's color when it leaves the station.

The mod has a map setting--the color blend ratio--that allows you to control how quickly the station's color converges to that of the train.
