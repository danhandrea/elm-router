module Router exposing
    ( Config
    , Options, CachePages(..), defaultOptions
    , Router, Msg
    , init, update, view, subscriptions
    , onUrlChange, onUrlRequest
    , map
    , url, route, page, viewport
    , redirect
    )

{-|

    Router


# Config

@docs Config


# Options

@docs Options, CachePages, defaultOptions


# Router Msg

@docs Router, Msg


# Basic

@docs init, update, view, subscriptions


# App url

@docs onUrlChange, onUrlRequest


# Map

@docs map


# Query

@docs url, route, page, viewport


# Navigation

@docs redirect


# Query

@docs currentUrl, currentRoute, currentViewPort

-}

import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom exposing (Viewport)
import Browser.Navigation as Nav exposing (Key)
import Dict exposing (Dict)
import Html as H exposing (Html)
import Task
import Url exposing (Url)
import Url.Parser as P exposing (Parser)


{-| Config
-}
type alias Config msg route page pageMsg =
    { bind : Msg pageMsg -> msg
    , parser : Parser (route -> route) route
    , notFound : Url -> route
    , init : route -> ( page, Cmd pageMsg )
    , update : pageMsg -> ( page, Cmd pageMsg )
    , view : page -> Html pageMsg
    , subscriptions : page -> Sub pageMsg
    , options : Options route
    }


type alias Options route =
    { cachePages : CachePages route
    , someOther_ : ()
    }


defaultOptions : Options route
defaultOptions =
    Options AlwaysCache ()


type CachePages route
    = AlwaysCache
    | NeverCache
    | CustomCache (route -> Bool)


{-| Router
-}
type Router route page
    = Router
        { url : Url
        , key : Key
        , base : Url
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

        ( initialRoute, initialPage, cmd ) =
            urlChanged config.parser initialUrl config.init config.notFound config.bind

        pages =
            Dict.singleton
                (Url.toString initialUrl)
                initialPage

        viewports =
            Dict.empty

        grabViewport =
            Task.perform (GrabViewport initialUrl False >> config.bind) Dom.getViewport
    in
    ( Router
        { url = initialUrl
        , key = key_
        , base = base_
        , route = initialRoute
        , pages = pages
        , viewports = viewports
        }
    , Cmd.batch [ cmd, grabViewport ]
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

        ( newPage, cmd ) =
            routeInit newRoute
    in
    ( newRoute, newPage, Cmd.map (bind << Page) cmd )


{-| Msg
-}
type Msg pageMsg
    = UrlRequest UrlRequest
    | UrlChanged Url
    | Page pageMsg
    | Subscription String pageMsg
    | GrabViewport Url Bool Viewport
    | SetViewport ()


{-| update
-}
update : Config msg route page pageMsg -> Msg pageMsg -> Router route page -> ( Router route page, Cmd msg )
update config message (Router ({ pages } as router)) =
    case message of
        UrlRequest request ->
            case request of
                Internal urlRequested ->
                    ( Router router
                    , Task.perform (GrabViewport urlRequested True >> config.bind) Dom.getViewport
                    )

                External urlRequested ->
                    ( Router router, Nav.load urlRequested )

        GrabViewport viewportUrl push grabbedViewport ->
            let
                viewports =
                    if Dict.member (Url.toString router.url) router.viewports then
                        Dict.update (Url.toString router.url) (\_ -> Just grabbedViewport) router.viewports

                    else
                        Dict.insert (Url.toString router.url) grabbedViewport router.viewports

                cmd =
                    if push then
                        Nav.pushUrl router.key (Url.toString viewportUrl)

                    else
                        Cmd.none
            in
            ( Router { router | viewports = viewports }, cmd )

        UrlChanged nextUrl ->
            let
                setViewportCmd =
                    Dict.get (Url.toString nextUrl) router.viewports
                        |> Maybe.map (\vp -> Task.perform (config.bind << SetViewport) (Dom.setViewport vp.viewport.x vp.viewport.y))
                        |> Maybe.withDefault Cmd.none

                newRoute =
                    P.parse config.parser nextUrl
                        |> Maybe.withDefault (config.notFound nextUrl)

                shouldCachePage =
                    case config.options.cachePages of
                        AlwaysCache ->
                            True

                        NeverCache ->
                            False

                        CustomCache f ->
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
            in
            ( Router { router | route = newRoute, pages = newPages, url = nextUrl }, Cmd.batch [ pageCommands, setViewportCmd ] )

        Page msg ->
            let
                ( newPage, cmd ) =
                    config.update msg

                newPages =
                    Dict.update (Url.toString router.url) (\_ -> Just newPage) pages
            in
            ( Router { router | pages = newPages }, Cmd.map (config.bind << Page) cmd )

        Subscription subscriptionUrl msg ->
            let
                ( newPage, cmd ) =
                    config.update msg

                newPages =
                    Dict.update subscriptionUrl (\_ -> Just newPage) pages
            in
            ( Router { router | pages = newPages }, Cmd.map (config.bind << Page) cmd )

        SetViewport _ ->
            ( Router router, Cmd.none )


{-| view
-}
view : Config msg route page pageMsg -> Router route page -> Html msg
view config (Router ({ pages } as router)) =
    Dict.get (Url.toString router.url) pages
        |> Maybe.andThen (Just << H.map (config.bind << Page) << config.view)
        |> Maybe.withDefault (H.div [] [ H.text "horrible error" ])


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
    bind << UrlChanged


{-| onUrlRequest
-}
onUrlRequest : (Msg pageMsg -> msg) -> UrlRequest -> msg
onUrlRequest bind =
    bind << UrlRequest


{-| currentUrl
-}
url : Router route page -> Url
url (Router router) =
    router.url


{-| redirect
-}
redirect : Config msg route page pageMsg -> Router route page -> String -> ( Router route page, Cmd msg )
redirect config ((Router { base }) as router) path =
    let
        url_ =
            { base | path = path }
    in
    update config (UrlRequest (Internal url_)) router


{-| currentUrl
-}
currentUrl : Router route -> Url
currentUrl (Router { url }) =
    url


{-| currentRoute
-}
currentRoute : Router route -> Maybe route
currentRoute (Router { url, routes }) =
    Dict.get (Url.toString url) routes


{-| currentViewPort
-}
currentViewPort : Router route -> Maybe Viewport
currentViewPort (Router { url, viewports }) =
    Dict.get (Url.toString url) viewports


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


{-| map
-}
map :
    (model -> page)
    -> (model -> msg -> pageMsg)
    -> ( model, Cmd msg )
    -> ( page, Cmd pageMsg )
map page_ pageMsg ( mdl, cmd ) =
    ( page_ mdl, Cmd.map (pageMsg mdl) cmd )
