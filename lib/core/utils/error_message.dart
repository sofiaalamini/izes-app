import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Texto em português para mostrar ao usuário a partir de qualquer erro.
///
/// Usa a mensagem amigável do [ApiException] (sessão expirada, sem conexão,
/// servidor indisponível...) e cai em [padrao] para erros desconhecidos.
String mensagemDeErro(Object? error, {required String padrao}) {
  if (error is ApiException) {
    final amigavel = error.friendlyMessage;
    return amigavel.startsWith('HTTP ') ? padrao : amigavel;
  }
  if (error is AuthException) return error.message;
  return padrao;
}
