#import "@preview/typslides:1.2.8": *

#set page(
  // footer: {
  //   [#grid(
  //     columns: (1fr, 1fr),
  //     rows: (auto, 20cm),
  //     gutter: 0pt,
  //     //grid.cell(
  //     //  colspan: 2,
  //     //  line(length: 100%, stroke: 0.5pt + gray)
  //     //),
  //     [#image("icechunk.svg", width: 10%, height: 10%)],
  //     [#image("earthmover.png", width: 50%)],
  //   )
  //   ]
  // },
  // margin: (bottom: 1cm)
)


// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "IosevkaTerm NF",
  link-style: "color",
  show-page-numbers: false,
)

// The front slide is the first slide of your presentation
#front-slide(
  title: "Zarr in Production Using Icechunk",
  // subtitle: [What can Icechunk do for you],
  authors: "Sebastian Galkin",
  info: [
    #box(inset: (left:4cm), image("icechunk.svg", width: 6.5cm))
    #box(inset: (left:4cm), image("summit.png", height: 7.6cm))
    
    #v(1fr)
    #h(1fr)
    #box(image("earthmover.png", width: 6cm))
    #h(1fr)
  ],
)

#slide(title: "The setup", outlined: true)[
```python
NUM_ROWS = 1_000
NUM_COLS = 2

def create_array(store: StoreLike) -> None:
    zarr.create_array(
        store=store, chunks=(1, 1), dtype=np.int8,
        data=np.zeros((NUM_ROWS, NUM_COLS))
    )

def mean(store: StoreLike) -> None:
    array = zarr.open_array(store)
    col = random.randint(0, NUM_COLS - 1)
    m = np.mean(array[:, col])
    print(f"Mean is {m}")
```
]

#slide(title: "The problem of interrupted updates", outlined: true)[
```python
array = zarr.open_array(store)
for x in range(NUM_ROWS):
    for y in range(NUM_COLS):
        array[x, y] = 1
        if random.random() < probability:
            raise ValueError("ingest broke")
```
#v(1fr)

#cols(columns: (1fr, 1fr), gutter: 0em)[
][
#image("aqueduct.png", width: 60%)
]
]

#slide(title: "The problem of interrupted updates", outlined: true)[
```python
array = zarr.open_array(store)
for x in range(NUM_ROWS):
    for y in range(NUM_COLS):
        array[x, y] = 1
        if random.random() < probability:
            raise ValueError("ingest broke")
```
#v(1fr)

#cols(columns: (1fr, 1fr), gutter: 0em)[
#framed[
    - Mean is 0.385
    - Mean is 0.115
    - Mean is 0.997
    - Mean is 1.0
  ]
][
#image("aqueduct.png", width: 60%)
]
]


#slide(title: "The problem with concurrent readers", outlined: true)[
#cols(columns: (2fr, 0.3fr, 1.5fr), gutter: 0em)[
#box(stroke:blue, inset:0.8em)[
  ```python
  def update(store: StoreLike) -> None:
      array = zarr.open_array(store)
      # Update every element to 1
      array[:] = 1
  ```
  ]
][
  #set align(center)
  #text(48pt)[#sym.arrows.bb]
][
#box(stroke:blue, inset:2em)[
```python
while True:
    mean(store)
```
]
]

#v(1fr)


#cols(columns: (1fr, 1fr), gutter: 0em)[
][
#image("race.png", width: 60%)
]
]

#slide(title: "The problem with concurrent readers", outlined: true)[
#cols(columns: (2fr, 0.3fr, 1.5fr), gutter: 0em)[
#box(stroke:blue, inset:0.8em)[
  ```python
  def update(store: StoreLike) -> None:
      array = zarr.open_array(store)
      # Update every element to 1
      array[:] = 1
  ```
  ]
][
  #set align(center)
  #text(48pt)[#sym.arrows.bb]
][
#box(stroke:blue, inset:2em)[
```python
while True:
    mean(store)
```
]
]

#v(1fr)


#cols(columns: (1fr, 1fr), gutter: 0em)[
#framed[
    - Mean is 0.0
    - Mean is 0.0
    - *Mean is 0.459*
    - Mean is 1.0
    - Mean is 1.0
  ]
][
#image("race.png", width: 60%)
]
]

#slide(title: "", outlined: true)[

  #h(1fr) #box(image("undo.png", height: 100%)) #h(1fr)
// ```python
// def update(store: StoreLike) -> None:
//     array = zarr.open_array(store)
//     array[:] = 2
// ```
// 
// #v(0.7fr)
// #framed[
//     - Mean is 2
//   ]
// #v(1fr)
]

#slide(title: "Icechunk = Zarr on ACID", outlined: true)[
  
  #cols(columns: (0.4fr, 2fr), gutter: 0em)[
    - #purply[A]tomic
    - #purply[C]onsistent
    - #purply[I]solated
    - #purply[D]urable
][
  #h(1fr) #box(image("acid.png", height: 110%)) #h(1fr)
]
]

#slide(title: "ACID can solve most problems", outlined: true)[
```python
def update(repo: ic.Repository) -> None:
    with repo.transaction("main", message="Update done") as store:
      array = zarr.open_array(store)
      array[:] = 1

while True:
    session = repo.readonly_session(branch="main")
    mean(session.store)
```
#v(1fr)

]

#slide(title: "ACID can solve most problems", outlined: true)[
```python
def update(repo: ic.Repository) -> None:
    with repo.transaction("main", message="Update done") as store:
      array = zarr.open_array(store)
      array[:] = 1

while True:
    session = repo.readonly_session(branch="main")
    mean(session.store)
```
#cols(columns: (1fr, 2fr), gutter: 0em)[
#framed[
- Mean is 0.0
- Mean is 0.0
- Mean is 1.0
]
][
  #purply[Updates become *atomic*, *consistent*, and *isolated*]
]

]

#slide(title: "Solving the Undo problem", outlined: true)[
#figure(
  image("branches.png", width: 80%,),
  caption: [],
  numbering: none,
)]

#slide(title: "Fully Zarr, Xarray, and Dask compatible", outlined: true)[
  ```python
import xarray as xr

ds = ...

# Start an icechunk session
session = repo.writable_session(branch = "test-xarray")

# write the data to zarr
ds.to_zarr(session.store, group='my_group')

# commit the data
session.commit("My first commit 🥹")
  ```
]

#slide(title: "Simple but powerful API", outlined: true)[

```python
# Git-like operations
repo.ancestry(...)

repo.create_branch(...)
repo.create_tag(...)
repo.lookup_branch(...)
repo.list_branches()

# Powerful features
repo.diff(
  from_branch="main",
  to_tag="v1.0"
)

# Conflict detection
Session.rebase(solver: ConflictSolver)
```

// #cols(columns: (0.9fr, 1fr), gutter: 8em)[
// ```python
// import icechunk as ic
// 
// repo=ic.Repository.open_or_create(...)
// 
// # make a session
// session =
//   repo.writable_session(...)
// 
// # get a store for Zarr/Xarray
// session.store
// snap_id = session.commit(...)
// ```
// ][
// ```python
// # Git-like operations
// repo.ancestry(...)
// 
// repo.create_branch(...)
// repo.create_tag(...)
// repo.lookup_branch(...)
// repo.list_branches()
// 
// repo.diff(
//   from_branch="main",
//   to_tag="v1.0"
// )
// ```
// ]

]

#slide(title: "Icechunk is fast out of the box", outlined: true)[
]

#slide(title: "Icechunk is fast out of the box", outlined: true)[
  #box(image("reads.png",height: 70%  ))
  #box(image("writes.png",height: 70%  ))
]

#slide(title: "Icechunk is production grade", outlined: true)[
  - Released 1 year ago
  - #purply[Open format] specification
  - `pip install icechunk==1.1.9`
  - Supported in `zarr-python` and `zarrs`
  - #purply[Any object store] (S3, GCS, R2, Azure blob, Tigris, MinIO, etc.)
  - Lots of organizations are using Icechunk for their #purply[production data]
  - #purply[Fully open source], Apache 2.0 licensed // #box(image("apache.svg", height: 0.6cm))
]

#slide(title: "Questions", outlined: true)[
  You can #purply[*start using Icechunk*] today
  - #link("https://icechunk.io")

For help:

  - Introductory #purply[workshop tomorrow] at 9am
  - Ask questions to the #link("https://earthmover.io")[Earthmover] team today or tomorrow
  - Play with Icechunk public datasets in Arraylake: https://earthmover.io/
  - Go to https://icechunk.io and join the Icechunk #purply[community slack]
  - Earthmover's blog
]
