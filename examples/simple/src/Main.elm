module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Html as H
import Html.Attributes as A
import Page exposing (Page)
import Route exposing (Route)
import Router exposing (Config, Router)
import Url exposing (Url)



-- MODEL


type alias Model =
    { router : Router Route Page }



-- MSG


type Msg
    = RouterMsg (Router.Msg Page.Msg)



-- ROUTER CONFIG


config : Config Msg Route Page Page.Msg
config =
    { init = Page.init
    , update = Page.update
    , view = Page.view
    , subscriptions = Page.subscriptions
    , msg = RouterMsg
    , parser = Route.parser
    , notFound = Route.NotFound
    , options = Router.defaultOptions
    }



-- INIT


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        ( router, cmd ) =
            Router.init config url key
    in
    ( Model router, cmd )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message ({ router } as model) =
    case message of
        RouterMsg msg ->
            let
                ( newRouter, cmd ) =
                    Router.update config msg router
            in
            ( { model | router = newRouter }, cmd )



-- VIEW


view : Model -> Document Msg
view { router } =
    let
        layout =
            Router.view config router
    in
    { title =
        layout.title
            |> Maybe.map (\pageTitle -> "App - " ++ pageTitle)
            |> Maybe.withDefault "App"
    , body =
        [ H.nav []
            [ H.a [ A.href "/" ] [ H.text "Home" ]
            , H.a [ A.href "/about" ] [ H.text "About" ]
            , H.a [ A.href "/contact" ] [ H.text "Contact" ]
            , H.a [ A.href "/something_not_routed" ] [ H.text "404" ]
            ]
        , H.main_ layout.attrs layout.main
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions { router } =
    Router.subscriptions config router



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = Router.onUrlChange RouterMsg
        , onUrlRequest = Router.onUrlRequest RouterMsg
        }
