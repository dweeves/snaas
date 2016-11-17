To avoid a singular type of reaction to Posts which ultimately leads to a gap in the expressiveness for users we want to follow the prominent example of other social networks and make a range of emotions available to our customers which they can expose as interactions on Posts and potentially other entities like Comments and Events themselves in the future. The proposed set of reactions includes six initial reactions including the already supported `like`:
- `like`: general endorsement
- `love`: heavily endorsed
- `haha`: entertained
- `wow`: impressed
- `sad`:
- `angry`: outraged

### API

Reaction read payload:

```
{
    "post_id": 321,
    "post_id_str": "321",
    "type": "sad",
    "user_id": 123,
    "user_id_str": "123"
}
```

Post read payload additions:

```
{
    ...
    "count" {
        ...
        "reactions": {
            "angry": 12,
            "haha": 5,
            "like": 3,
            "love": 1,
            "sad": 17,
            "wow": 4
        }
    },
    ...
}
```

The surface will be extended under the Posts namespace and offers an endpoint for reaction with the minimum CRUD capabilities to list the reactions and create and delete per user. Those will offer the same idempotent characteristics that likes offer as a single reaction per user to a post is a binary thing.
- `GET /posts/<postID>/reactions[?type=like|love|haha|wow|sad|angry]`: List all or filtered reactions for the Post.
- `PUT /posts/<postID>/reactions/<like|love|haha|wow|sad|angry>`: Create typed reaction for current uesr if not exists.
- `DELETE /posts/<postID>/reactions/<like|love|haha|wow|sad|angry>`: Delete typed reaction for current user if exists.

Additionally we provide endpoints for reactions per user.
- `GET /me/reactions[?type=like|love|haha|wow|sad|angry]`: List all or filtered reactions for the current user.
- `GET /users/<userID>/reactions[?type=like|love|haha|wow|sad|angry]`: List all or filtered reactions for the user.
### Internal

In order to support the more diverse use-cases around reactions we plan to introduce a new entity with corresponding service.

``` go
import (
    "github.com/tapglue/multiverse/platform/metrics"
    "github.com/tapglue/multiverse/platform/service"
)

// ReactionType variants available.
const (
    TypeLike ReactionType = iota
    TypeLove
    TypeHaha
    TypeWow
    TypeSad
    TypeAngry
)

// List is a Reaction collection.
type List []*Reaction

// QueryOptions are passed to narrow down queries.
type QueryOptions struct {
    ObjectIDs []uint64
    Types     []ReactionType
    UserIDs   []uint64
}

// Reaction is a user reaction on an entity on an emotional range.
type Reaction struct {
    ObjectID uint64
    Type     ReactionType
    UserID   uint64
}

// ReactionType is type of Reactions.
type ReactionType uint8

// Service for Reaction interactions.
type Service interface {
    metrics.BucketByDay
    service.Lifecycle

    Count(namespace string, opts QueryOptions) (int, error)
    Put(namespace string, object *Reaction) (*Reaction, error)
    Query(namespace string, opts QueryOptions) (List, error)
}
```

### Questions

* How extensible is the `type` to potentially support more reactions? @onurakpolat
* Is there a way to support reactions of type emoji with the emoji in the payload? (We could still translate the emoji into meaningful annotation) @onurakpolat

### Estimations
- new Reaction service: 2 days
- implement Post endpoints: 2 days
- implement User endpoints: 1 day
- implement Android: 1.5 days
- implement iOS: 1.5 days
