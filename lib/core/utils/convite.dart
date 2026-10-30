/// Sobras comuns ao copiar o código: aspas (retas e curvas do iPhone), colchetes,
/// vírgula e ponto e vírgula. O código em si só tem letras, números, `-`, `_` e `.`.
const _sobras = '"\'`<>[](){}“”‘’,;';

/// Limpa o código de convite como veio de copiar e colar: espaços, quebras de linha
/// e as sobras acima nas pontas, até a linha inteira do JSON (`"convite": "eyJ...",`).
String normalizarConvite(String bruto) {
  var texto = bruto.replaceAll(RegExp(r'\s+'), '');
  final doisPontos = texto.lastIndexOf(':');
  if (doisPontos >= 0) {
    texto = texto.substring(doisPontos + 1);
  }

  var inicio = 0;
  var fim = texto.length;
  while (inicio < fim && _sobras.contains(texto[inicio])) {
    inicio++;
  }
  while (fim > inicio && _sobras.contains(texto[fim - 1])) {
    fim--;
  }
  return texto.substring(inicio, fim);
}

/// Convite que veio no link de cadastro (`.../app/?convite=...`), ou `null`.
String? conviteDoLink(Uri link) {
  final valor = link.queryParameters['convite'];
  if (valor == null) return null;
  final limpo = normalizarConvite(valor);
  return limpo.isEmpty ? null : limpo;
}
