import type { GraphQLResolveInfo } from 'graphql';
import { errors } from '@strapi/utils';

type NotesArgs = {
  filters?: Record<string, unknown>;
  pagination?: Record<string, unknown>;
  sort?: string | string[];
};

type NoteArgs = {
  documentId?: string;
};

type ResolverNext<A> = (
  parent: unknown,
  args: A,
  context: unknown,
  info: GraphQLResolveInfo,
) => Promise<unknown>;

export default function middlewaresAndPolicies() {
  return {
    resolversConfig: {
      'Query.notes': {
        middlewares: [
          // Soft-delete invariant — rejection half.
          // The `archived` field is server-controlled. Any caller-supplied filter on `archived` is rejected up front.
          async (
            next: ResolverNext<NotesArgs>,
            parent: unknown,
            args: NotesArgs,
            context: unknown,
            info: GraphQLResolveInfo,
          ) => {
            // if (args?.filters?.archived !== undefined) {
            if (args?.filters?.archived) {
              throw new errors.ForbiddenError(
                'Cannot filter on `archived` directly. Soft-deleted notes are not accessible via the public API.',
              );
            }
            return next(parent, args, context, info);
          },
          // Soft-delete invariant — injection half.
          // The first middleware guarantees `archived` was undefined here, so the injection is unconditional.
          async (
            next: ResolverNext<NotesArgs>,
            parent: unknown,
            args: NotesArgs,
            context: unknown,
            info: GraphQLResolveInfo,
          ) => {
            args.filters = {
              ...(args?.filters ?? {}),
              archived: { eq: false },
            };
            return next(parent, args, context, info);
          },
          // Timing logger.
          // Wraps the rest of the chain to record how long Query.notes
          // takes. Sees the final filter value because both soft-delete middlewares ran first.
          async (
            next: ResolverNext<NotesArgs>,
            parent: unknown,
            args: NotesArgs,
            context: unknown,
            info: GraphQLResolveInfo,
          ) => {
            const label = `[graphql] Query.notes (${JSON.stringify(args?.filters ?? {})})`;
            console.time(label);
            try {
              return await next(parent, args, context, info);
            } finally {
              console.timeEnd(label);
            }
          },
        ],
        policies: ['global::cap-page-size'],
      },
      'Query.note': {
        middlewares: [
          // Soft-delete invariant — single-fetch coverage.
          // Direct documentId lookup is a separate code path from Query.notes and needs its own enforcement.
          // Let the resolver run so the entity is loaded, then inspect `archived` on the result and surface NotFoundError if it is true.
          // From the public API's point of view, an archived note simply does not exist.
          async (
            next: ResolverNext<NoteArgs>,
            parent: unknown,
            args: NoteArgs,
            context: unknown,
            info: GraphQLResolveInfo,
          ) => {
            const result = (await next(parent, args, context, info)) as
              | { archived?: boolean }
              | null
              | undefined;
            if (result && result.archived === true) {
              throw new errors.NotFoundError('Note not found.');
            }
            return result;
          },
          async (
            next: ResolverNext<NotesArgs>,
            parent: unknown,
            args: NotesArgs,
            context: unknown,
            info: GraphQLResolveInfo,
          ) => {
            const label = `[graphql] Query.note (${JSON.stringify(args?.filters ?? {})})`;
            console.time(label);
            try {
              return await next(parent, args, context, info);
            } finally {
              console.timeEnd(label);
            }
          },
        ],
      },
    },
  };
}
