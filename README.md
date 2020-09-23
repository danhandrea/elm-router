# elm-router

This library helps with routing in elm [applications](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application).

## Features

- Maintain state of all opened pages
- Remember [Viewport](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Viewport) of opened pages. (scroll position)
- Manage page update, view
- Manage page subscriptions individually (subscriptions from previously opened pages will run in background)

## Change log

- 1.0.1 Added example
- 1.0.2 Added example passing data from model to parser so you can use that data in page init
- 1.1.0 Added query methods: currentUrl, currentRoute, currentViewPort

## To do

- ? Rename message NoOp to -> SetViewport
- ? Rename message GrabViewportPushUrl to GetViewport/GrabViewport
-

## Notes

- [Official Guide](https://guide.elm-lang.org/) might be easier for your app
- Added simple example

## Config

```elm
type alias Config msg route routeMsg =
    { parser : Parser (route -> route) route
    , update : routeMsg -> ( route, Cmd routeMsg )
    , view : route -> List (Html routeMsg)
    , message : Msg routeMsg -> msg
    , subscriptions : route -> Sub routeMsg
    , notFound : Url -> List (Html msg)
    , routeTitle : route -> Maybe String
    }
```

## Usage (assume file Route.elm containing)

Two static pages with no model and one with a model, message, and subscription:

```elm
type Route
    = Home
    | About
    | Contact Contact.Model

type Msg
    = ContactMsg Contact.Model Contact.Msg
```

You will need to provide the **parser** like:

```elm
parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Router.mapRoute Parser.top Home
        , Router.mapRoute (Parser.s "about") About
        , Router.mapRoute (Parser.s "contact") <| Contact <| Contact.init "" ""
        ]
```

An **update** function like:

```elm
update : Msg -> ( Route, Cmd Msg )
update message =
    case message of
        ContactMsg model msg ->
            Contact.update msg model
                |> Router.mapUpdate Contact ContactMsg
```

A **view** function like:

```elm
view : Route -> List (Html Msg)
view route =
    case route of
        Home ->
            Home.view

        About ->
            About.view

        Contact mdl ->
            Contact.view mdl
                |> Router.mapMsg (ContactMsg mdl)
```

A **subscriptions** function like:

```elm
subscriptions : Route -> Sub Msg
subscriptions route =
    case route of
        Home ->
            Sub.none

        About ->
            Sub.none

        Contact mdl ->
            Contact.subscriptions mdl
                |> Sub.map (ContactMsg mdl)
```

A **title** function like:

```elm
title : Route -> Maybe String
title route =
    case route of
        Home ->
            Nothing

        About ->
            Just "About"

        Contact _ ->
            Just "Contact"
```

And a **notFound** function like:

where

```elm
import Html as H exposing (Html)
import Url exposing (Url)

notFound : Url -> List (Html msg)
notFound url =
    [ H.h1 [] [ H.text "Page not found!" ]
    , H.h3 [] [ H.text <| Url.toString url ]
    ]
```

build a `Config` like:

```elm
config : Config App.Msg Route Route.Msg
config =
    { parser = Route.parser
    , update = Route.update
    , view = Route.view
    , message = App.Router
    , subscriptions = Route.subscriptions
    , notFound = Route.notFound
    , routeTitle = Route.title
    }
```

where:

- `App.Msg` is your application `Msg`
- `App.Router` is the message in your application `Msg` created for the `Router`

And use the **config** created in **your** application like:

Assuming:

```elm
import Route exposing (Route)
import Router

type alias Model =
    { router : Router Route }

type Msg
    = Router (Router.Msg Route.Msg)
```

then :

```elm
init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        router =
            Router.init config url key
    in
    ( Model router, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update message ({ router } as model) =
    case message of
        Router msg ->
            let
                ( newRouter, cmd ) =
                    Router.update config msg router
            in
            ( { model | router = newRouter }, cmd )

view : Model -> Document Msg
view { router } =
    { title = Router.title router "My app"
    , body =
        [ H.nav []
            [ H.a [ A.href "/" ] [ H.text "Home" ]
            , H.a [ A.href "/about" ] [ H.text "About" ]
            , H.a [ A.href "/contact" ] [ H.text "Contact" ]
            , H.a [ A.href "/something_not_routed" ] [ H.text "404" ]
            ]
        , H.main_ [] (Router.view config router)
        ]
    }

subscriptions : Model -> Sub Msg
subscriptions { router } =
    Router.subscriptions config router

main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = Router.onUrlChange config
        , onUrlRequest = Router.onUrlRequest config
        }
```
