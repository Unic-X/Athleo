package main

import(
    "os"
    "fmt"
    "log"
    "context"
    "net/http"
	"cloud.google.com/go/firestore"
    "github.com/go-chi/chi/v5"
    firebase "firebase.google.com/go"
    "google.golang.org/api/option"
)

var fsClient *firestore.Client
var ctx context.Context

func setupFirestore(){
    ctx = context.Background()
    conf := &firebase.Config{ProjectID: "athleo-b82a3"}
    sa := option.WithCredentialsFile("./athleo-pk.json")
    app, err := firebase.NewApp(ctx, conf, sa)
    if err != nil {
        log.Fatalln(err)
    }

    client, err := app.Firestore(ctx)
    if(err != nil){
        log.Fatalln(err)
    }

    fsClient = client
    fmt.Println("firestore setup successful")
}


func main(){
    fmt.Println(GOOGLE_API_KEY)
    router := chi.NewRouter()
    router.Get(
        "/getroutes",
        getRoutes,
        )
    setupFirestore()
    http.ListenAndServe(":3000", router)
}
