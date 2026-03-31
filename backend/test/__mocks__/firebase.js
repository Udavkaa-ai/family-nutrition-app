/**
 * Shared Firebase mock for all tests.
 * Import via jest.mock('../src/config/firebase', () => require('./__mocks__/firebase'))
 */

const makeDocRef = (id, data, exists = true) => {
  const self = {
    id,
    exists,
    data: () => data,
    get: jest.fn().mockResolvedValue({ exists, id, data: () => data }),
    update: jest.fn().mockResolvedValue({}),
    set: jest.fn().mockResolvedValue({}),
    delete: jest.fn().mockResolvedValue({}),
  };
  self.ref = self;
  return self;
};

const makeCollection = (defaultData = {}) => ({
  doc: jest.fn((id) => makeDocRef(id || 'mock-id', defaultData)),
  where: jest.fn(() => ({
    limit: jest.fn(() => ({
      get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
    })),
    orderBy: jest.fn(() => ({
      limit: jest.fn(() => ({
        get: jest.fn().mockResolvedValue({ docs: [] }),
      })),
    })),
    get: jest.fn().mockResolvedValue({ docs: [] }),
  })),
  add: jest.fn().mockResolvedValue({ id: 'mock-new-id' }),
});

const db = {
  collection: jest.fn(() => makeCollection()),
  batch: jest.fn(() => ({
    set: jest.fn(),
    update: jest.fn(),
    commit: jest.fn().mockResolvedValue({}),
  })),
};

const auth = {
  verifyIdToken: jest.fn().mockResolvedValue({ uid: 'mock-uid' }),
};

module.exports = { admin: {}, db, auth };
