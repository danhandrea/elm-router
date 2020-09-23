module Router exposing
    ( Router, Config, Msg
    , onUrlChange, onUrlRequest, title
    , init
    , update
    , view
    , subscriptions
    , mapMsg, mapRoute, mapUpdate
    , currentUrl, currentRoute, currentViewPort
    )

{-| Router

Manages elm routing pages


# Router, Config, Msg

@docs Router, Config, Msg


# Application

@docs onUrlChange, onUrlRequest, title


# init

@docs init


# update

@docs update


# view

@docs view


# subscriptions

@docs subscriptions


# mapping

@docs mapMsg, mapRoute, mapUpdate


# Query

@docs currentUrl, currentRoute, currentViewPort

-}

import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom exposing (Viewport)
import Browser.Navigation as Navigation exposing (Key)
import Dict exposing (Dict)
import Html as H exposing (Html)
import Task
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)



-- ALIASES


type alias Routes route =
    Dict String route


type alias Viewports =
    Dict String Viewport



-- MODEL


{-| Router
-}
type Router route
    = Router
        { url : Url
        , key : Key
        , pageTitle : Maybe String
        , viewports : Viewports
        , routes : Routes route
        }



-- MSG


{-| Msg
-}
type Msg routeMsg
    = UrlChanged Url
    | UrlRequest UrlRequest
    | Route routeMsg
    | Sub String routeMsg
    | GrabViewport Url Viewport
    | NoOp



-- CONFIG


{-| Config
-}
type alias Config msg route routeMsg =
    { parser : Parser (route -> route) route
    , update : routeMsg -> ( route, Cmd routeMsg )
    , view : route -> List (Html routeMsg)
    , message : Msg routeMsg -> msg
    , subscriptions : route -> Sub routeMsg
    , notFound : Url -> List (Html msg)
    , routeTitle : route -> Maybe String
    }



-- INIT


notFoundTitle : Maybe String
notFoundTitle =
    Just "Not found!"


{-| Init
-}
init : Config msg route routeMsg -> Url -> Key -> Router route
init { parser, routeTitle } url key =
    let
        empty =
            { url = url
            , key = key
            , pageTitle = Nothing
            , viewports = Dict.empty
            , routes = Dict.empty
            }
    in
    case Parser.parse parser url of
        Nothing ->
            Router { empty | pageTitle = notFoundTitle }

        Just route ->
            Router
                { empty
                    | routes = Dict.singleton (Url.toString url) route
                    , pageTitle = routeTitle route
                }



-- UPDATE


{-| update
-}
update : Config msg route routeMsg -> Msg routeMsg -> Router route -> ( Router route, Cmd msg )
update config message (Router router) =
    case message of
        UrlRequest request ->
            case request of
                Internal newUrl ->
                    ( Router router
                    , Task.perform (GrabViewport newUrl >> config.message) Dom.getViewport
                    )

                External newUrl ->
                    ( Router router
                    , Navigation.load newUrl
                    )

        UrlChanged newUrl ->
            let
                ( route, routes ) =
                    change config newUrl router.routes

                cmd =
                    case Dict.get (Url.toString newUrl) router.viewports of
                        Just vp ->
                            Task.perform (\_ -> config.message NoOp) (Dom.setViewport vp.viewport.x vp.viewport.y)

                        Nothing ->
                            Cmd.none
            in
            ( Router
                { router
                    | url = newUrl
                    , routes = routes
                    , pageTitle = Maybe.withDefault notFoundTitle <| Maybe.map config.routeTitle route
                }
            , cmd
            )

        GrabViewport url viewport ->
            ( Router
                { router
                    | viewports =
                        if Dict.member (Url.toString router.url) router.viewports then
                            Dict.update (Url.toString router.url) (\_ -> Just viewport) router.viewports

                        else
                            Dict.insert (Url.toString router.url) viewport router.viewports
                }
            , Navigation.pushUrl router.key (Url.toString url)
            )

        Route msg ->
            let
                ( route, cmd ) =
                    config.update msg
            in
            ( Router
                { router
                    | routes =
                        Dict.update (Url.toString router.url)
                            (Maybe.map (\_ -> route))
                            router.routes
                }
            , Cmd.map (Route >> config.message) cmd
            )

        Sub url msg ->
            let
                ( route, cmd ) =
                    config.update msg
            in
            ( Router
                { router
                    | routes =
                        Dict.update url
                            (Maybe.map (\_ -> route))
                            router.routes
                }
            , Cmd.map (Route >> config.message) cmd
            )

        NoOp ->
            ( Router router, Cmd.none )



-- CHANGE


{-| change
-}
change : Config msg route routeMsg -> Url -> Routes route -> ( Maybe route, Routes route )
change { parser } url routes =
    case Parser.parse parser url of
        Nothing ->
            ( Nothing, routes )

        Just route ->
            let
                urlString =
                    Url.toString url
            in
            if Dict.member urlString routes then
                ( Just route, routes )

            else
                ( Just route, Dict.insert urlString route routes )



-- VIEW


{-| view
-}
view : Config msg route routeMsg -> Router route -> List (Html msg)
view config (Router router) =
    case Dict.get (Url.toString router.url) router.routes of
        Nothing ->
            config.notFound router.url

        Just route ->
            List.map (H.map (Route >> config.message)) (config.view route)



-- SUBSCRIPTIONS


{-| subscriptions
-}
subscriptions : Config msg route routeMsg -> Router route -> Sub msg
subscriptions config (Router { routes }) =
    routes
        |> Dict.toList
        |> List.map
            (\( key, route ) ->
                Sub.map (Sub key >> config.message) (config.subscriptions route)
            )
        |> Sub.batch



-- EXPOSE MESSAGES


{-| onUrlChange
-}
onUrlChange : Config msg route routeMsg -> Url -> msg
onUrlChange config =
    UrlChanged >> config.message


{-| onUrlRequest
-}
onUrlRequest : Config msg route routeMsg -> UrlRequest -> msg
onUrlRequest config =
    UrlRequest >> config.message



-- GENERAL


{-| title
-}
title : Router route -> String -> String
title (Router { pageTitle }) appTitle =
    case pageTitle of
        Nothing ->
            appTitle

        Just t ->
            appTitle ++ " - " ++ t


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



-- MAPPING


{-| mapUpdate
-}
mapUpdate : (routeModel -> routeType) -> (routeModel -> routeMsg -> msgType) -> ( routeModel, Cmd routeMsg ) -> ( routeType, Cmd msgType )
mapUpdate modelInto msgInto ( mdl, msg ) =
    ( modelInto mdl, Cmd.map (msgInto mdl) msg )


{-| mapMsg
-}
mapMsg : (routeMsg -> msgType) -> List (Html routeMsg) -> List (Html msgType)
mapMsg msg =
    List.map (H.map msg)


{-| mapRoute
-}
mapRoute : Parser a routeType -> a -> Parser (routeType -> b) b
mapRoute where_ what =
    Parser.map what where_
