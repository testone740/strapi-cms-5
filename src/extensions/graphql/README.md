## Scaling beyond one file

Keeping every custom query in **`queries.ts`**, every custom mutation in **`mutations.ts`**, and every computed field in **`computed-fields.ts`** is a **role-based** layout: one file per kind of code. It works well while each file is under about 200 lines and the project has a small number of content types with custom logic.

Once a file passes that threshold, or the project grows to many content types, the natural next step is a **feature-based** layout: one folder per content type.

```txt
src/extensions/graphql/
├── index.ts                       # aggregator
├── note/
│   ├── index.ts                   # barrel combining everything below
│   ├── types.ts                   # TagCount, NoteStats
│   ├── queries.ts                 # searchNotes, noteStats, notesByTag
│   ├── mutations.ts               # togglePin, archiveNote, duplicateNote
│   └── computed-fields.ts         # Note.wordCount, readingTime, excerpt
├── article/
│   └── ...
└── shared/
    └── types.ts                   # types used across multiple features
```

Each feature file exports its own factory that returns its own **`nexus.extendType({ type: "Query" })`** (or **`Mutation`**, or whatever it needs). Nexus is fine with the same type being extended in many places: at startup it gathers every extension of **Query** from every factory and merges them, so the feature files do not have to know about each other. The **`index.ts`** inside each feature folder pulls together the types, the **`resolversConfig`**, and any nested factories. The top-level **`index.ts`** registers each feature with the GraphQL plugin.

## Four guidelines, whichever layout you pick:

1. **One factory per file, registered at the top**. Each file exports a factory that returns **`{ types, resolversConfig }, or calls extensionService.use(...)`** directly. The top-level **`index.ts`** is the only place that calls **`extensionService.use(...)`** for everything in your project.
1. Keep object types next to the resolver that returns them. **`TagCount`** is only used by **`NoteStats.byTag`**, and **`NoteStats`** is only returned by **`noteStats`**. So **`TagCount`** belongs in the Notes feature folder. Move a type into a **`shared/`** folder only when more than one feature actually returns it.
1. **Do not write your own helper to register resolvers**. Nexus already does that job. **`t.list.field("searchNotes", { ... })`** is what the GraphQL plugin expects; if you wrap it in something like **`registerQuery(config)`**, you lose TypeScript's inline type-checking on the resolver and you get nothing back in return.
1. **Do not split too early**. A single 200-line **`queries.ts`** is easier to read than a six-file feature folder where everything imports from everything else. Split when the file is genuinely hard to navigate, not before.
