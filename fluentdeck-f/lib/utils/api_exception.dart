/// Thrown when the Strapi API returns a non-success HTTP status.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.body});

  final int statusCode;
  final String message;
  final dynamic body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
