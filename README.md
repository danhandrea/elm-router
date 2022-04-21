# elm-router

This library helps with routing in elm [applications](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application).

## Features

- Maintain state of all opened pages (optional, custom)
- Remember [Viewport](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Viewport) of opened pages. (scroll position)
- Manage page init, update, view
- Manage page subscriptions individually (subscriptions from previously opened pages will run in background)
- Optional navigation delay, so you can add css animations for page transitions
- Subscribe to notifications for UrlRequested and UrlChanged


## Change log

- 1.0.1 Added example
- 1.0.2 Added example passing data from model to parser so you can use that data in page init
- 1.1.0 Added query methods: currentUrl, currentRoute, currentViewPort
- 2.0.0
  - Added onUrlChanged to config so you will be notified if the url has changed (optional)
  - Modified init so it will grab viewport
- 3.0.0
  - Brought back init (not sure what I was thinking)
- 4.0.0
  - Refactor some names
  - Add navigation delay
  - Add animaiton example
  - Add router events

## Notes

- [Official Guide](https://guide.elm-lang.org/) might be easier for your app

## Usage

See `examples` folder