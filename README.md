# IP Connect ![](https://github.com/pawong/IPConnect/blob/d6d0bfed522e99b60daf7c99852108cdc280175f/IP%20Connect/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png)

Shows the internet status, external and internal IP address in your Mac menu bar. Get up to date connection notifications when the status changes.

- Icons in color or black and white.
- Show external IP on menubar.
- Use system notifications of changes.

## Screenshots
![](Screenshot1.png)

## Versions
>[1.0.9](builds/IPConnect_v1.0.9/IPConnect.zip)
>    Changes:
>    - Ventura bug fixes

>[1.0.8](builds/IPConnect_v1.0.8/IPConnect.zip)
>    Changes:
>    - First Open Source Release


## Notes

You can enable `Location Services` via the commandline to map your current location. I've found that this can cause memory to leak, however, it never leaks a huge amount.

1. Quit IP Connect. And or kill the process by double clicking on it in the activity monitor and choosing Quit.
2. Open a terminal.
3. At the prompt, type the following command:
    ```bash
    open -a /Applications/IP\ Connect.app/ --args -L:1
    ```
    Use 1 for enabling, 0 fr disabling.

## Support

**Bugs and requests?**  Please use the project's [issue tracker].

[![Issues](http://img.shields.io/github/issues/pawong/IPConnect.svg)](https://github.com/pawong/IPConnect/issues)

**Want to contribute?**  Please fork this repository and open a pull request with your new changes.

[![Pull requests](http://img.shields.io/github/issues-pr/pawong/IPConnect.svg?maxAge=3600)](https://github.com/pawong/IPConnect/pulls)

**Do you like it?**  Support the project by starring the repository or [tweet] about it.

## Thanks for looking! If you like what you see [!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/pawong)

**IP Connect** © 2022, Mazookie, LLC. Released under the [MIT License](LICENSE).

[tweet]: https://twitter.com/intent/tweet?
[issue tracker]: https://github.com/pawong/IPConnect/issues/new

![](https://www.mazookie.com/img/Mazookie_full_logo_sticker_small.png)

Q: What is Mazookie?

A: Mazookie is a company that used to put apps on the MacOS App Store. This doesn't happen any more because Apple charges money to be a developer and there's no money in these apps, so the projects have been opensourced. Yeah, free stuff!
