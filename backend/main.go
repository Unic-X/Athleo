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
    "firebase.google.com/go/auth"
    "google.golang.org/api/option"
)

var fsClient *firestore.Client
var authClient *auth.Client
var ctx context.Context

func initFirebase() {
	ctx = context.Background()
    sa := option.WithCredentialsFile("./athleo-pk.json")
	app, err := firebase.NewApp(ctx, nil, sa)
	if err != nil {
		log.Fatalf("error initializing firebase app: %v", err)
	}
	
    firebaseAuthClient, err := app.Auth(ctx)
	if err != nil {
		log.Fatalf("error getting Auth client: %v", err)
	}

    authClient = firebaseAuthClient
    
    client, err := app.Firestore(ctx)
    if(err != nil){
        log.Fatalln(err)
    }

    fsClient = client
    fmt.Println("firestore setup successful")
}


func main(){
    GOOGLE_API_KEY = os.Getenv("GOOGLE_API_KEY")
    router := chi.NewRouter()
    router.Get(
        "/getroutes",
        getRoutes,
        )
    initFirebase()
    http.ListenAndServe(":5000", router)
}
