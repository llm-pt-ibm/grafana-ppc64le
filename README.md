# grafana-ppc64le


Este repositório descreve a compilação nativa do [Grafana](https://github.com/grafana/grafana) para IBM POWER9 (ppc64le). O Grafana não publica binários oficiais para essa arquitetura. A IBM mantém imagens oficiais dessa ferramenta, porém as ultimas versões presentes no repositório estão desatualizadas.

Este repositório compila o Grafana a partir do código-fonte dentro de um build Docker multi-stage, então atualizar para um novo release do Grafana não exige repetir o processo de compilação manual. Veja [Atualizando para uma nova versão](#atualizando-para-uma-nova-versão) abaixo.

Este trabalho é parte do projeto [Multi-Arq](#), uma colaboração entre UFCG, IBM e Flex Brazil focada em portar, validar e otimizar aplicações para ppc64le.

## Início rápido

Baixe a imagem já compilada:

```bash
docker pull ufcgibm/grafana-ppc64le:13.1.0-ppc64le

docker run -d \
  --name grafana-ppc64le \
  -p 3000:3000 \
  ufcgibm/grafana-ppc64le:13.1.0-ppc64le
```

O Grafana ficará disponível em `http://localhost:3000`.

## Compilando a partir do código-fonte

```bash
docker build -t ufcgibm/grafana-ppc64le:13.1.0-ppc64le .
```

## Atualizando para uma nova versão

Quando sair um novo release do Grafana, sobrescreva os build args em vez de repetir os passos manuais do zero:

```bash
docker build \
  --build-arg GRAFANA_VERSION=v0.13.2 \
  --build-arg SWC_CORE_VERSION=1.15.40 \
  -t ufcgibm/grafana-ppc64le:0.13.2-ppc64le .
```

O `SWC_CORE_VERSION` também pode precisar mudar — veja [Problemas conhecidos](#problemas-conhecidos).

## Ambiente de build

| Componente | Versão |
|---|---|
| Imagem base | almalinux:8 |
| GCC | Toolset 11 (11.2.1) |
| Go | 1.26.5 |
| Node.js | 22.22.2 |
| Yarn | 4.15.0 |
| Python | 3.11 |

Validado em um servidor IBM Power9 (ppc64le, 16 CPUs) rodando AlmaLinux 8.10.

## Problemas conhecidos

### O `@swc/core` não tem binário nativo para ppc64le na versão que o Grafana fixa

O build do frontend do Grafana (Node.js + Yarn + Nx + Webpack) depende do `@swc/core`. A versão fixada no `package.json` do Grafana no momento deste build (`1.13.3`) não tem binário nativo para `linux-ppc64le`.

Correção: atualizar para uma versão que tenha (`1.15.40` funcionou para o Grafana 13.1.0) e atualizar o lockfile com `yarn install`. O Dockerfile faz isso automaticamente através do build arg `SWC_CORE_VERSION` — consulte os [releases do swc no GitHub](https://github.com/swc-project/swc/releases) caso uma versão futura do Grafana precise de outro valor.

### Alguns plugins de datasource embutidos falham ao iniciar (esperado)

Na inicialização, os logs mostram erros como:

```
Could not start plugin backend" pluginId=elasticsearch error="fork/exec .../gpx_grafana_elasticsearch_datasource_linux_ppc64le: no such file or directory"
```

Isso é esperado e não indica um build quebrado. Plugins como Elasticsearch e Zipkin são distribuídos como binários pré-compilados separados (não fazem parte do `make build`), e o projeto oficial só publica esses binários para arquiteturas como amd64/arm64, não ppc64le. O Grafana registra o erro no log, mas continua funcionando normalmente; a funcionalidade principal (dashboards, datasource do Prometheus, etc.) não é afetada.


## Matriz de compatibilidade

| Versão do Grafana | Status | Notas |
|---|---|---|
| 13.1.0 | ✅ Validado | `@swc/core` atualizado para 1.15.40. `/api/health` confirmado OK. Plugins embutidos do Elasticsearch/Zipkin falham ao iniciar (esperado, ver Problemas conhecidos). |

## Disclaimer

Este trabalho não é um release oficial ou distribuição de software da IBM, e não é desenvolvido ou suportado pela IBM ou pelo Grafana Labs.

Este trabalho foi desenvolvido pela Universidade Federal de Campina Grande (UFCG), uma universidade pública brasileira, como parte de um projeto de Pesquisa, Desenvolvimento e Inovação conduzido em parceria com a IBM e a Flex Brazil.
