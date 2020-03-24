module Main exposing (main)

import Api.Object
import Api.Object.Cat
import Api.Object.Dog
import Api.Object.Size
import Api.Query
import Api.Scalar
import Api.Union.Animal
import Browser
import Graphql.Http
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, button, div, h1, pre, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Model RemoteData.NotAsked RemoteData.NotAsked RemoteData.NotAsked, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Size =
    { height : Int
    , weight : Int
    }


{-| Client-side representation of data returned from GraphQL call when only the `id` field is requested. This is
non-nullable on both Dog and Cat.
-}
type SimpleAnimal
    = SimpleDog Api.Scalar.Id
    | SimpleCat Api.Scalar.Id


{-| Client-side representation of data returned from GraphQL call when the `id` and `name` properties are requested.
`name` is non-nullable on Dog, and nullable on Cat.
-}
type ScalarOnlyAnimal
    = ScalarOnlyDog Api.Scalar.Id String
    | ScalarOnlyCat Api.Scalar.Id (Maybe String)


{-| Client-side representation of data returned from GraphQL call when the `id`, `name` and `size` properties are
requested. `size` is non-nullable on Dog, and nullable on Cat.
-}
type ScalarAndObjectAnimal
    = ScalarAndObjectDog Api.Scalar.Id String Size
    | ScalarAndObjectCat Api.Scalar.Id (Maybe String) (Maybe Size)


type alias RemoteAnimalResult animal =
    Result (Graphql.Http.Error (List animal)) (List animal)


type alias RemoteAnimalList animal =
    RemoteData (Graphql.Http.Error (List animal)) (List animal)


type alias Model =
    { simpleAnimals : RemoteAnimalList SimpleAnimal
    , scalarOnlyAnimals : RemoteAnimalList ScalarOnlyAnimal
    , scalarAndObjectAnimals : RemoteAnimalList ScalarAndObjectAnimal
    }



-- UPDATE


type Msg
    = SimpleAnimalsRequested
    | SimpleAnimalsReceived (RemoteAnimalResult SimpleAnimal)
    | ScalarOnlyAnimalsRequested
    | ScalarOnlyAnimalsReceived (RemoteAnimalResult ScalarOnlyAnimal)
    | ScalarAndObjectAnimalsRequested
    | ScalarAndObjectAnimalsReceived (RemoteAnimalResult ScalarAndObjectAnimal)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SimpleAnimalsRequested ->
            ( { model | simpleAnimals = RemoteData.Loading }, loadSimpleAnimals )

        SimpleAnimalsReceived result ->
            case result of
                Ok animals ->
                    ( { model | simpleAnimals = RemoteData.Success animals }, Cmd.none )

                Err error ->
                    ( { model | simpleAnimals = RemoteData.Failure error }, Cmd.none )

        ScalarOnlyAnimalsRequested ->
            ( { model | scalarOnlyAnimals = RemoteData.Loading }, loadScalarOnlyAnimals )

        ScalarOnlyAnimalsReceived result ->
            case result of
                Ok animals ->
                    ( { model | scalarOnlyAnimals = RemoteData.Success animals }, Cmd.none )

                Err error ->
                    ( { model | scalarOnlyAnimals = RemoteData.Failure error }, Cmd.none )

        ScalarAndObjectAnimalsRequested ->
            ( { model | scalarAndObjectAnimals = RemoteData.Loading }, loadScalarAndObjectAnimals )

        ScalarAndObjectAnimalsReceived result ->
            case result of
                Ok animals ->
                    ( { model | scalarAndObjectAnimals = RemoteData.Success animals }, Cmd.none )

                Err error ->
                    ( { model | scalarAndObjectAnimals = RemoteData.Failure error }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ -- Div with simple data (just requesting ID of animals, which is required for both Cat and Dog).
          div []
            [ h1 [] [ text "Simple Data" ]
            , dataView model.simpleAnimals SimpleAnimalsRequested
            , div []
                [ text "This request should succeed as the request is as follows"
                , pre [ style "background-color" "lightgray" ] [ text """  query {
    animals {
      __typename
      ... on Dog {
        id3905593358: id    <-- Same ID here...
      }
      ... on Cat {
        id3905593358: id    <-- ... and here
      }
    }
  }
""" ]
                ]
            , text "The `id` field is given the same alias as it is exactly the same type for both Dog and Cat, namely a non-nullable string."
            ]
        , -- Div with scalar-only data (like above, but with additional string "name" field, which is non-nullable on
          -- Dog, but nullable on Cat).
          div []
            [ h1 [] [ text "Scalar Only Data" ]
            , dataView model.scalarOnlyAnimals ScalarOnlyAnimalsRequested
            , div []
                [ text "This request should succeed as the request is as follows"
                , pre [ style "background-color" "lightgray" ] [ text """  query {
    animals {
      __typename
      ... on Dog {
        id3905593358: id
        name3832528868: name  <-- Different ID here...
      }
      ... on Cat {
        id3905593358: id
        name12867311: name    <-- ... and here
      }
    }
  }
""" ]
                ]
            , text "The `name` field is given a different alias for Dog and Cat as it is a different type on each: nullable on one; non-nullable on the other."
            ]
        , -- Div with scalar-and-object data (like above, but with additional "size" field, whose value is an
          -- object, and which is non-nullable on Dog, but nullable on Cat).
          div []
            [ h1 [] [ text "Scalar And Object Data" ]
            , dataView model.scalarAndObjectAnimals ScalarAndObjectAnimalsRequested
            , div []
                [ text "This request should fail as the request is as follows"
                , pre [ style "background-color" "lightgray" ] [ text """  query {
    animals {
      __typename
      ... on Dog {
        id3905593358: id
        name3832528868: name
        size {                      <-- Same (unaliased) ID here...
          height1207450440: height
          weight1207450440: weight
        }
      }
      ... on Cat {
        id3905593358: id
        name12867311: name
        size {                      <-- ... and here
          height1207450440: height
          weight1207450440: weight
        }
      }
    }
  }
""" ]
                ]
            , text "The `size` field is given the same ID (with no alias) even though the type is different on Dog and Cat: nullable on one; non-nullable on the other."
            ]
        ]


dataView : RemoteAnimalList animal -> Msg -> Html Msg
dataView animalData loadRequestedMsg =
    let
        ( description, colour ) =
            case animalData of
                RemoteData.NotAsked ->
                    ( "", "" )

                RemoteData.Loading ->
                    ( "Loading", "gray" )

                RemoteData.Failure e ->
                    ( "Error", "red" )

                RemoteData.Success a ->
                    ( "Success", "green" )
    in
    div []
        [ div []
            [ button [ onClick loadRequestedMsg ] [ text "Load" ]
            , span [ style "color" colour, style "font-size" "150%", style "font-weight" "bold" ] [ text description ]
            ]
        ]



-- GRAPHQL


loadSimpleAnimals : Cmd Msg
loadSimpleAnimals =
    let
        selection =
            Api.Union.Animal.fragments
                { onDog = SelectionSet.map SimpleDog Api.Object.Dog.id
                , onCat = SelectionSet.map SimpleCat Api.Object.Cat.id
                }
    in
    Api.Query.animals selection
        |> Graphql.Http.queryRequest "/graphql"
        |> Graphql.Http.send SimpleAnimalsReceived


loadScalarOnlyAnimals : Cmd Msg
loadScalarOnlyAnimals =
    let
        selection =
            Api.Union.Animal.fragments
                { onDog = SelectionSet.map2 ScalarOnlyDog Api.Object.Dog.id Api.Object.Dog.name
                , onCat = SelectionSet.map2 ScalarOnlyCat Api.Object.Cat.id Api.Object.Cat.name
                }
    in
    Api.Query.animals selection
        |> Graphql.Http.queryRequest "/graphql"
        |> Graphql.Http.send ScalarOnlyAnimalsReceived


loadScalarAndObjectAnimals : Cmd Msg
loadScalarAndObjectAnimals =
    let
        sizeSelection : SelectionSet Size Api.Object.Size
        sizeSelection =
            SelectionSet.map2 Size Api.Object.Size.height Api.Object.Size.weight

        selection =
            Api.Union.Animal.fragments
                { onDog = SelectionSet.map3 ScalarAndObjectDog Api.Object.Dog.id Api.Object.Dog.name (Api.Object.Dog.size sizeSelection)
                , onCat = SelectionSet.map3 ScalarAndObjectCat Api.Object.Cat.id Api.Object.Cat.name (Api.Object.Cat.size sizeSelection)
                }
    in
    Api.Query.animals selection
        |> Graphql.Http.queryRequest "/graphql"
        |> Graphql.Http.send ScalarAndObjectAnimalsReceived
