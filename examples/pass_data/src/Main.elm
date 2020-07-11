module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Html as H
import Html.Attributes as A
import Route exposing (Route)
import Router exposing (Config, Router)
import Url exposing (Url)



-- MODEL


type alias Model =
    { router : Router Route
    , foo : String
    }



-- MSG


type Msg
    = Router (Router.Msg Route.Msg)



-- ROUTER CONFIG


config : String -> Config Msg Route Route.Msg
config a =
    { parser = Route.parser a
    , update = Route.update
    , view = Route.view
    , message = Router
    , subscriptions = Route.subscriptions
    , notFound = Route.notFound
    , routeTitle = Route.title
    }



-- INIT


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        foo =
            "Bar"

        router =
            Router.init (config foo) url key
    in
    ( Model router foo, Cmd.none )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message ({ router, foo } as model) =
    case message of
        Router msg ->
            let
                ( newRouter, cmd ) =
                    Router.update (config foo) msg router
            in
            ( { model | router = newRouter }, cmd )



-- VIEW


view : Model -> Document Msg
view { router, foo } =
    { title = Router.title router "My app"
    , body =
        [ H.nav []
            [ H.a [ A.href "/" ] [ H.text "Home" ]
            , H.a [ A.href "/about" ] [ H.text "About" ]
            , H.a [ A.href "/contact" ] [ H.text "Contact" ]
            , H.a [ A.href "/something_not_routed" ] [ H.text "404" ]
            ]
        , H.main_ [] (Router.view (config foo) router)
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions { router, foo } =
    Router.subscriptions (config foo) router



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = Router.onUrlChange <| config ""
        , onUrlRequest = Router.onUrlRequest <| config ""
        }
