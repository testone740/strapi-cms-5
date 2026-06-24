import { factories } from '@strapi/strapi';
import { errors } from '@strapi/utils';

const enforceSoftDelete = (ctx, next) => {
  const filters = (ctx.query.filters ??= {}) as Record<string, unknown>;

  // Rejection half: match the GraphQL behavior. If the caller tried to
  // filter on `archived`, return a clear FORBIDDEN error instead of
  // silently overwriting their filter.
  if (filters.archived !== undefined) {
    throw new errors.ForbiddenError(
      'Cannot filter on `archived` directly. Soft-deleted notes are not accessible via the public API.',
    );
  }

  // Injection half: every other request is forced to `archived: false`.
  filters.archived = { $eq: false };
  return next();
};

export default factories.createCoreRouter('api::note.note', {
  config: {
    find: { middlewares: [enforceSoftDelete] },
    findOne: { middlewares: [enforceSoftDelete] },
  },
});

// export default factories.createCoreRouter('api::note.note');
