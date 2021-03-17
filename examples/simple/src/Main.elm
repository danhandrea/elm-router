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
    { router : Router Route Page
    , foo_ : ()
    }



-- MSG


type Msg
    = Router (Router.Msg Page.Msg)



-- ROUTER CONFIG


config : Config Msg Route Page Page.Msg
config =
    Config Router Route.parser Route.NotFound Page.init Page.update Page.view Page.subscriptions Router.defaultOptions



-- INIT


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        ( router, cmd ) =
            Router.init config url key
    in
    ( Model router (), cmd )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message ({ router } as model) =
    case message of
        Router msg ->
            let
                ( newRouter, cmd ) =
                    Router.update config msg router
            in
            ( { model | router = newRouter }, cmd )



-- VIEW


view : Model -> Document Msg
view { router } =
    { title = "My app"
    , body =
        [ H.nav []
            [ H.a [ A.href "/" ] [ H.text "Home" ]
            , H.a [ A.href "/about" ] [ H.text "About" ]
            , H.a [ A.href "/contact/foo/foo@bar" ] [ H.text "Contact foo" ]
            , H.a [ A.href "/contact/bar/bar@foo" ] [ H.text "Contact bar" ]
            , H.a [ A.href "/something_not_routed" ] [ H.text "404" ]
            ]
        , Router.view config router
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
        , onUrlChange = Router.onUrlChange Router
        , onUrlRequest = Router.onUrlRequest Router
        }
