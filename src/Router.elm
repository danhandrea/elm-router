module Router exposing
    ( Config
    , Options, Cache(..), defaultOptions
    , Router, Msg
    , Layout
    , init, update, view, subscriptions
    , onUrlChange, onUrlRequest
    , mapUpdate, mapView
    , url, route, page, viewport, base, key
    , redirect, reload, replaceUrl, external
    , Event(..)
    )

{-|

    Router


# Config

@docs Config


# Options

@docs Options, Cache, defaultOptions


# Router Msg

@docs Router, Msg


# Layout

@docs Layout


# Basic

@docs init, update, view, subscriptions


# App url

@docs onUrlChange, onUrlRequest


# Map

@docs mapUpdate, mapView


# Query

@docs url, route, page, viewport, base, key


# Navigation

@docs redirect, reload, replaceUrl, external


# Events

@docs Event

-}

import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom exposing (Viewport)
import Browser.Navigation as Nav exposing (Key)
import Dict exposing (Dict)
import Html as H exposing (Attribute, Html)
import Html.Attributes as A
import Process
import Task
import Url exposing (Url)
import Url.Parser as P exposing (Parser)


{-| Config

bind
Your router Msg eg `RouterMsg (Router.Msg Page.Msg)`

parser
Your `Route` parser

notFound
Your not found `Route`

init
Your `Page` init

update
Your `Page` update

view
Your `Page` view

subscriptions
Your `Page` subscriptions

options
`Router` options

-}
type alias Config msg route page pageMsg =
    { bind : Msg pageMsg -> msg
    , parser : Parser (route -> route) route
    , notFound : Url -> route
    , init : route -> ( page, Cmd pageMsg )
    , update : pageMsg -> page -> ( page, Cmd pageMsg )
    , view : page -> Layout pageMsg
    , subscriptions : page -> Sub pageMsg
    , options : Options route msg
    }


{-| Router options

cache
cache strategy

cacheExceptions
paths to ignore caching for, useful for pages like login
where you don't want the inputs to remain filled.

navigation delay
add delay to navigation so you can animate page transitions

onEvent
receive notifications for Router events

-}
type alias Options route msg =
    { cache : Cache route
    , cacheExceptions : List String
    , navigationDelay : Maybe Float
    , onEvent : Maybe (Event -> msg)
    }


{-| Event

Basic router events

-}
type Event
    = UrlRequested Url
    | UrlChanged Url


{-| default options

Always use cache

No exceptions

No navigation delay

No events

-}
defaultOptions : Options route msg
defaultOptions =
    Options Always [] Nothing Nothing


{-| Cache rules
-}
type Cache route
    = Always
    | Never
    | Custom (route -> Bool)


{-| Layout

title
Set a title for each page.

attrs
Attributes that will be set on the container.

main
Html content to be set inside the container.

-}
type alias Layout msg =
    { title : Maybe String
    , attrs : List (Attribute msg)
    , main : List (Html msg)
    }


{-| Router
-}
type Router route page
    = Router
        { url : Url
        , key_ : Key
        , base_ : Url
        , route : route
        , pages : Dict String page
        , viewports : Dict String Viewport
        }


{-| init
-}
init : Config msg route page pageMsg -> Url -> Key -> ( Router route page, Cmd msg )
init config initialUrl key_ =
    let
        base_ =
            { initialUrl | query = Nothing, fragment = Nothing, path = "/" }

        ( initialRoute, initialPage, initialPageCmd ) =
            urlChanged config.parser initialUrl config.init config.notFound config.bind

        pages =
            Dict.singleton
                (Url.toString initialUrl)
                initialPage

        viewports =
            Dict.empty

        grabViewport =
            Task.perform (GrabViewport initialUrl False Push >> config.bind) Dom.getViewport
    in
    ( Router
        { url = initialUrl
        , key_ = key_
        , base_ = base_
        , route = initialRoute
        , pages = pages
        , viewports = viewports
        }
    , Cmd.batch [ initialPageCmd, grabViewport ]
    )


urlChanged :
    Parser (route -> route) route
    -> Url
    -> (route -> ( page, Cmd pageMsg ))
    -> (Url -> route)
    -> (Msg pageMsg -> msg)
    -> ( route, page, Cmd msg )
urlChanged parser nextUrl routeInit notFoundRoute bind =
    let
        newRoute =
            P.parse parser nextUrl
                |> Maybe.withDefault (notFoundRoute nextUrl)

        ( newPage, newPageCmd ) =
            routeInit newRoute
    in
    ( newRoute, newPage, Cmd.map (bind << Page) newPageCmd )


{-| Msg
-}
type Msg pageMsg
    = Page pageMsg
    | UrlRequest NavigationMode UrlRequest
    | UrlChange Url
    | SetViewport ()
    | Subscription String pageMsg
    | GrabViewport Url Bool NavigationMode Viewport
    | DelayedNavigationTo Url NavigationMode


type NavigationMode
    = Push
    | Replace


{-| update
-}
update : Config msg route page pageMsg -> Msg pageMsg -> Router route page -> ( Router route page, Cmd msg )
update config message (Router ({ pages } as router)) =
    case message of
        UrlRequest navigationMode request ->
            case request of
                Internal ({ path } as urlRequested) ->
                    if List.member path config.options.cacheExceptions then
                        ( Router router, Nav.load <| Url.toString urlRequested )

                    else
                        ( Router router
                        , Task.perform (GrabViewport urlRequested True navigationMode >> config.bind) Dom.getViewport
                        )

                External urlRequested ->
                    ( Router router, Nav.load urlRequested )

        GrabViewport viewportUrl push navigationMode grabbedViewport ->
            let
                viewports =
                    if Dict.member (Url.toString router.url) router.viewports then
                        Dict.update (Url.toString router.url) (\_ -> Just grabbedViewport) router.viewports

                    else
                        Dict.insert (Url.toString router.url) grabbedViewport router.viewports

                ( navigationCommand, eventCommand ) =
                    if push then
                        let
                            navCmd =
                                case config.options.navigationDelay of
                                    Just time ->
                                        delay time (DelayedNavigationTo viewportUrl navigationMode |> config.bind)

                                    Nothing ->
                                        Nav.pushUrl router.key_ (Url.toString viewportUrl)
                        in
                        ( navCmd, trigger config.options.onEvent <| UrlRequested viewportUrl )

                    else
                        ( Cmd.none, Cmd.none )
            in
            ( Router { router | viewports = viewports }, Cmd.batch [ navigationCommand, eventCommand ] )

        DelayedNavigationTo navUrl navigationMode ->
            case navigationMode of
                Push ->
                    ( Router router, Nav.pushUrl router.key_ (Url.toString navUrl) )

                Replace ->
                    ( Router router, Nav.replaceUrl router.key_ (Url.toString navUrl) )

        UrlChange nextUrl ->
            let
                setViewportCmd =
                    Dict.get (Url.toString nextUrl) router.viewports
                        |> Maybe.map (\vp -> Task.perform (config.bind << SetViewport) (Dom.setViewport vp.viewport.x vp.viewport.y))
                        |> Maybe.withDefault Cmd.none

                newRoute =
                    P.parse config.parser nextUrl
                        |> Maybe.withDefault (config.notFound nextUrl)

                shouldCachePage =
                    case config.options.cache of
                        Always ->
                            True

                        Never ->
                            False

                        Custom f ->
                            f newRoute

                ( newPages, pageCommands ) =
                    if Dict.member (Url.toString nextUrl) pages then
                        if not shouldCachePage then
                            let
                                ( newPage, pageCmd ) =
                                    config.init newRoute
                                        |> Tuple.mapSecond (Cmd.map (config.bind << Page))
                            in
                            ( Dict.update (Url.toString nextUrl) (\_ -> Just newPage) pages, pageCmd )

                        else
                            ( pages, Cmd.none )

                    else
                        let
                            ( newPage, pageCmd ) =
                                config.init newRoute
                                    |> Tuple.mapSecond (Cmd.map (config.bind << Page))
                        in
                        ( Dict.insert (Url.toString nextUrl) newPage pages, pageCmd )

                eventCmd =
                    trigger config.options.onEvent <| UrlChanged nextUrl
            in
            ( Router { router | route = newRoute, pages = newPages, url = nextUrl }, Cmd.batch [ pageCommands, setViewportCmd, eventCmd ] )

        Page msg ->
            case Dict.get (Url.toString router.url) pages of
                Just currentPage ->
                    let
                        ( newPage, cmd ) =
                            config.update msg currentPage

                        newPages =
                            Dict.update (Url.toString router.url) (\_ -> Just newPage) pages
                    in
                    ( Router { router | pages = newPages }, Cmd.map (config.bind << Page) cmd )

                _ ->
                    ( Router router, Cmd.none )

        Subscription subscriptionUrl msg ->
            case Dict.get subscriptionUrl pages of
                Just currentPage ->
                    let
                        ( newPage, cmd ) =
                            config.update msg currentPage

                        newPages =
                            Dict.update subscriptionUrl (\_ -> Just newPage) pages
                    in
                    ( Router { router | pages = newPages }, Cmd.map (config.bind << Page) cmd )

                _ ->
                    ( Router router, Cmd.none )

        SetViewport _ ->
            ( Router router, Cmd.none )


{-| view
-}
view : Config msg route page pageMsg -> Router route page -> Layout msg
view config (Router ({ pages } as router)) =
    Dict.get (Url.toString router.url) pages
        |> Maybe.andThen (Just << mapView (config.bind << Page) << config.view)
        |> Maybe.withDefault (Layout (Just "Err") [] [ H.text "horrible error" ])


{-| subscriptions
-}
subscriptions : Config msg route page pageMsg -> Router route page -> Sub msg
subscriptions config (Router { pages }) =
    pages
        |> Dict.toList
        |> List.map
            (\( key_, page_ ) ->
                Sub.map (Subscription key_ >> config.bind) (config.subscriptions page_)
            )
        |> Sub.batch


{-| onUrlChange
-}
onUrlChange : (Msg pageMsg -> msg) -> Url -> msg
onUrlChange bind =
    bind << UrlChange


{-| onUrlRequest
-}
onUrlRequest : (Msg pageMsg -> msg) -> UrlRequest -> msg
onUrlRequest bind =
    UrlRequest Push >> bind


{-| base
-}
base : Router route page -> Url
base (Router router) =
    router.base_


{-| currentUrl
-}
url : Router route page -> Url
url (Router router) =
    router.url


{-| redirect
-}
redirect : Config msg route page pageMsg -> Router route page -> String -> ( Router route page, Cmd msg )
redirect config ((Router { base_ }) as router) path =
    let
        url_ =
            { base_ | path = path }
    in
    update config (UrlRequest Push (Internal url_)) router


{-| replaceUrl

    Same as redirect but uses `Browser.Navigation` replaceUrl

-}
replaceUrl : Config msg route page pageMsg -> Router route page -> String -> ( Router route page, Cmd msg )
replaceUrl config ((Router { base_ }) as router) path =
    let
        url_ =
            { base_ | path = path }
    in
    update config (UrlRequest Replace (Internal url_)) router


{-| reload

This never results in a page load!
It will just re-init the current page

-}
reload : Config msg route page pageMsg -> Router route page -> ( Router route page, Cmd msg )
reload config (Router r) =
    let
        ( updatedRoute, updatedPage, cmd ) =
            urlChanged config.parser r.url config.init config.notFound config.bind

        newPages =
            Dict.update (Url.toString r.url) (\_ -> Just updatedPage) r.pages
    in
    ( Router { r | route = updatedRoute, pages = newPages }
    , cmd
    )


{-| external

Same as redirect exept is an external link

-}
external : Config msg route page pageMsg -> Router route page -> String -> ( Router route page, Cmd msg )
external config router url_ =
    update config (UrlRequest Push (External url_)) router


{-| currentRoute
-}
route : Router route page -> route
route (Router router) =
    router.route


{-| currentPage
-}
page : Router route page -> Maybe page
page (Router ({ pages } as router)) =
    Dict.get (Url.toString router.url) pages


{-| currentViewPort
-}
viewport : Router route page -> Maybe Viewport
viewport (Router ({ viewports } as router)) =
    Dict.get (Url.toString router.url) viewports


{-| key

Might cause issues if used outside of router, not sure

-}
key : Router route page -> Key
key (Router { key_ }) =
    key_


{-| map update
-}
mapUpdate :
    (model -> page)
    -> (msg -> pageMsg)
    -> ( model, Cmd msg )
    -> ( page, Cmd pageMsg )
mapUpdate page_ pageMsg ( mdl, cmd ) =
    ( page_ mdl, Cmd.map pageMsg cmd )


{-| map view
-}
mapView : (msgA -> msgB) -> Layout msgA -> Layout msgB
mapView m lA =
    let
        mappedSections =
            lA.main
                |> List.map (H.map m)

        mappedAttrs =
            lA.attrs
                |> List.map (A.map m)
    in
    Layout lA.title mappedAttrs mappedSections


delay : Float -> a -> Cmd a
delay time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity


trigger : Maybe (b -> a) -> b -> Cmd a
trigger mEvent msg =
    case mEvent of
        Just ev ->
            Task.succeed (ev msg) |> Task.perform identity

        Nothing ->
            Cmd.none
