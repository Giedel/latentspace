abstract class BaseRepository<T> {
  Future<void> insert(T item);
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> update(T item);
  Future<void> delete(String id);
}