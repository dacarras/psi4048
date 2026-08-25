// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#import "@preview/fontawesome:0.5.0": *
#set text()
#show heading: set text(font: ("Roboto",), weight: 700, fill: rgb("#666666"), )
#show raw.where(block: false): set text(font: ("Hack",), fill: rgb("#222222"), )
#show raw.where(block: false): content => highlight(fill: rgb("#f1f3f5"), content)
#show raw.where(block: true): set text(font: ("Hack",), )
#show raw.where(block: true): set block(fill: rgb("#f1f3f5"))

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  title: [c03: Modelo Rasch],
  subtitle: [psi4048],
  authors: (
    ( name: [https:\/\/dacarras.github.io/],
      affiliation: [],
      email: [] ),
    ),
  date: [August 25, 2026],
  font: ("Inter",),
  fontsize: 0.8em,
  heading-family: ("Roboto",),
  heading-weight: 700,
  heading-color: rgb("#666666"),
  toc: true,
  toc_title: [Content],
  toc_indent: 1.5em,
  toc_depth: 3,
  cols: 1,
  doc,
)

#pagebreak()
= Introducción
<introducción>
- Vamos a emplear los ítems del módulo latinoamericano de ICCS 2009, o también llamado #emph[test regional de conocimiento cívico];. Este instrumento incluye 16 preguntas de selección múltiple. Estas preguntas fueron diseñadas para evaluar el mismo constructo que el test general, y fueron "calibradas" en un mismo que el test general, de modo que se pueden comparar a las dificultades de este test corto, con el test general (Schulz et al., 2011, p153).

- De este test, contamos con 5 items liberados (ver Agencia de Calidad, 2015). Con estos items liberados podemos hacernos una idea del tipo de preguntas que respondieron los estudiantes de octavo grado.

- Vamos a emplear los datos de Chile de ICCS 2009, para ilustrar como preparar los datos, y como ajustar modelos IRT Rasch, y hacer interpretación de resultados.

= Modelo Rasch
<modelo-rasch>
- Una forma de expresar al modelo Rasch es por medio de la siguiente ecuación:

$ l n [P r (y_(i p) = 1)] = theta_p - delta_i $

- En términos genéricos este modelo lo podemos interpretar de la siguiente forma: las respuestas correctas ( $y_(i p) = 1$ ) a cada ítem $""_i$ de cada persona $""_p$ sobre un instrumento, son condicionales a la habilidad ($theta$) de las personas $""_p$ y la dificultad ($delta$) de cada item $""_i$.

- Esta es una forma particular de especificar al modelo Rash, para obtener resultados mediante #emph[Marginal Maximum Likelihood] (MML, ver nota).

- Los modelos Rasch pueden ser considerados un caso especial de un modelo mixto (i.e., modelo multinivel), donde las personas son el nivel 2, y las respuestas son el nivel 1. Las dificultades son efectos fijos de los ítems respecto a las respuestas, y las respuestas anidadas en personas producen un efecto aleatorio (i.e., una media latente).

- En términos de ecuaciones estructurales, los modelos Rasch son modelos de variables latentes, de un solo factor que condiciona a respuestas dicotómicas, y con pendiente fija (o factor loading constreñido a uno).

- En términos generales, se puede considerar que el modelo Rasch es muy similar a un modelo ANOVA (#emph[analysis of variance];), en que se divide la varianza entre las personas y al interior de las personas (atribuible a los ítems). Con la salvedad de que la variable de respuesta no es continua, sino dicotómica.

- Existen diferentes formas de obtener los términos de interés de este modelo. En este ejemplo vamos a emplear una librería capaz de estimar modelos mixtos de tipo generalizado (i.e., que puede ajustar regresiones logísticas con efecto aleatorio) llamada `PLmixed`, y además vamos a emplear a la librería `TAM`, la cual estima modelos Rasch de forma canónica. Es decir, de la forma traduciional. La primera librería la vamos a emplear para ilustrar que los modelos Rasch, estimados con MML, son casos especiales de un modelo mixto generalizado. La segunda libería la usaremos para ilustrar el uso de TAM.

#block[
#callout(
body: 
[
Existen al menos tres formas de producir resultados de modelos Rasch: Conditional Maximum Likelihood (CML), Joint Maximum Likelihood (JML), y Marginal Maximum Likelihood (MML) (Wind et al., 2022). El modelo original de Rasch carece de supuestos distribucionales para los términos $delta_i$ y $theta_p$. Y de esta forma, CML, JML y MML son diferentes formas de estimar (i.e., producir) resultados de los términos de interés del modelo. CML, por ejemplo, reemplaza a $theta_p$ por el estadístico suficiente del modelo: el puntaje total (i.e., la suma de respuestas). JML por su parte, incluye a las personas como efecto fijo y por tanto $theta_p$ carece de varianza. Finalmente, MML incluye a $theta_p$ como efecto aleatorio, y por tanto le brinda una media cero, e incluye una varianza libre. Además, estos diferentes modelos pueden ser reparametrizados, por lo que en vez de centrar a las personas ( $theta_p$ ) con media cero, se constriñen los delta a que sumen cero (Wu et al., 2016). Los diferentes software que ajustan modelos Rasch emplean algunas de estas formas de estimación, e incluyen #emph[defaults] respecto a como parametrizar el modelo ajustado.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
= Flujo de trabajo
<flujo-de-trabajo>
- En el curso he enfatizado una secuencia de trabajo que nos puede servir. Esta forma de trabajo, supone un flujo de trabajo que posee ciertos pasos, los cuales, por lo general, forman parte de la generación de resultados con un propósito.

- Estos pasos son:

  - #emph[Abrir] los datos
  - #emph[Preparar] los datos
  - #emph[Calcular] cifras
  - #emph[Formatear] resultados
  - #emph[Mostrar] resultados

- En el presente documento, como estamos interesados en la ilustración de los modelos Rasch para items dicotómicos, vamos a quebrar este flujo; pero emplearemos estos diferentes pasos secuenciales para mostrar resultados.

- En la siguiente sección, vamos a ilustrar los pasos llevados a cabo para ajustar un modelo Rasch, sobre los items de conocimiento cívico del Modulo Latinoamericano de ICCS 2009.

== Abrir los datos
<abrir-los-datos>
- Vamos a abrir los datos que se encuentran en formato #emph[SPSS];. Estos son archvivos de extensión `*.sav`. Vamos a emplear a la libreria `haven`, para que R pueda leer estos datos.

#block[
#callout(
body: 
[
`library(haven)` puede cargar en sesión de R diferentes formatos de bases de datos incluyendo a datos de SPSS, SAS, y Stata, los cuales son los software estadísticos más comunes con los que se difunden los datos secundarios de varios estudios de gran escala. #strong[ICCS] tradicionalmente es hecho público con datos en formato SPSS, y #strong[PISA] comparte sus datos en formato SPSS y SAS.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#block[
```r
#---------------------------------------------------------------
# load data
#---------------------------------------------------------------

# latinoamerican module
data_chl <- haven::read_sav('ISLCHLC2.sav')

# international background questionnaire
data_que <- haven::read_sav('ISGCHLC2.sav')
```

]
== Preparar los datos
<preparar-los-datos>
- Vamos a crear una base de datos reducida, la cual contiene los datos que queremos analizar, y unas cuantas variables más (e.g., escolaridad de los padres, SES, dependencia escolar de las escuelas de Chile, entre otras). Sin embargo, el foco central esta en el uso de los items del test de interés, variables `LS2T01`-`LS2T16`.

- Además, vamos a instalar una librería para estudios de gran escala, la cual tiene diferentes #emph[wrapper functions] para operaciones muy comunes en estudios de gran escala. En este caso, vamos a emplear a esta función para operaciones sencillas, como extraer información de los labels de los datos, y crear puntaje #emph[z];.

#block[
```r
install.packages('devtools')
devtools::install_github('dacarras/ilsa',force = TRUE)
```

]
#block[
#callout(
body: 
[
#link("https://github.com/dacarras/ilsa")[`library(ilsa)`] es una librería en desarrollo la cual contiene diferentes funciones comúnmente empleadas para trabajar con datos de gran escala, como la normalización de pesos muestrales, la creación de pesos #emph[jackknife] replicados para ICCS, y otras funciones para extrar información de labels de datos. Es una libreria que incluye a un subconjunto de funciones presentes en #link("https://github.com/dacarras/r4sda")[`library(r4sda)`] solo que esta segunda librería es aun más experimental, y sufre cambios de manera más frecuente que la primera.

]
, 
title: 
[
Advertencia
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
- Para analizar a estas variables ( `LS2T01`-`LS2T16` ), necesitamos corregir las respuestas observadas como correctas e incorrectas. En #strong[Anexo 1] se encuentran las frecuencias de respuestas de cada ítem, las cuales indican cual es la respuesta correcta esperada con un `*`. Por ejemplo:

```

> ilsa::variable_label(data_chl$LS2T14)
[1] "STATE RESPONSIBILITY FOR JUSTICE SYSTEM"

> dplyr::count(data_chl, LS2T14, rec_key(LS2T14, key = 1))

  LS2T14                                  `rec_key(LS2T14, key = 1)`     n
  <dbl+lbl>                                                    <dbl> <int>
1  1 [STATE IS THE ONLY ONE IN CHARGE*]                            1  3276
2  2 [STEALING IS NOT AS BAD AS HITTING]                           0   694
3  3 [PUNISHMENT NOT SUFFICIENTLY SEVERE]                          0   522
4  4 [ONLY THE POLICE COULD HIT HIM]                               0   625
```

```r
knitr::include_graphics('./03_img/LS2T14_liberado.jpg')
```

#align(center)[#box(image("./03_img/LS2T14_liberado.jpg"))]
- Luego de que hemos corregido las respuestas observadas, por la clasificación de respuestas correctas e incorrectas, agregamos luego variables que se encuentran en la base de datos del cuestionario internacional, y no son parte del modulo latinoamericano. Recuperamos el indicador de nivel socioeconómico (variable `ses`, indicador original `NISB`), y recuperamos la escolaridad de los padres. Adicionalmente, recolectamos diferentes puntajes de conocimiento cívico que provee el estudio. Entre estos, se encuentran: a) los valores plausibles; b) `NWLCIV` el cual es un puntaje IRT, pero solo los #emph[weighted least estimate] de los 79 ítems internacionales, y c) `KNOWLMLE` es un puntaje IRT (de tipo MLE), que se genera solo con los ítems ancla con el estudio CIVED (versión previa del estudio ICCS 2009, llamado CIVED 1999).

- Con la base de datos generada, que llamamos `data_model`, nos encontramos en condiciones de ajustar modelos IRT sobre los ítems de interés.

#block[
```r
#---------------------------------------------------------------
# prep data
#---------------------------------------------------------------

data_cov <- data_que %>%
            mutate(edu = case_when(
            HISCED == 5 ~ 1,
            HISCED == 4 ~ 0,
            HISCED == 3 ~ 0,  
            HISCED == 2 ~ 0,
            HISCED == 1 ~ 0,
            HISCED == 0 ~ 0
            )) %>%
            mutate(ses = ilsa::z_score(NISB)) %>%
            dplyr::select(
            IDCNTRY,   # identficador único del pais
            IDSTUD,    # identficador único del estudiante
            IDSCHOOL,  # identficador único de la escuela
            NWLCIV,    # National civic knowledge scale (international test)
            KNOWLMLE,  # CIVED content knowledge scale (15 linking test)
            PV1CIV,    # Valores plausibles de Civic Knowledge (Prueba internacional)
            PV2CIV,    # Valores plausibles de Civic Knowledge (Prueba internacional)
            PV3CIV,    # Valores plausibles de Civic Knowledge (Prueba internacional)
            PV4CIV,    # Valores plausibles de Civic Knowledge (Prueba internacional)
            PV5CIV,    # Valores plausibles de Civic Knowledge (Prueba internacional)
            ses,       # Indicador de nivel socioeconómico (estandarizado al país)
            edu        # Dummy de educación terciaria de los padres (Universitaria)
            )

#------------------------------------------------
# reference
#------------------------------------------------

# Nota: ver
#
# Brese, F., Jung, M., Mirazchiyski, P., Schulz, W., & Zuehlke, O. (2011). 
# ICCS 2009 User Guide for the International Database, Supplement 3.
# International Association for the Evaluation of Educational Achievement (IEA).

#------------------------------------------------
# data for modelling
#------------------------------------------------

data_model <- data_chl %>%
            mutate(id_p = as.numeric(seq(1:nrow(.)))) %>%
            mutate(sex = case_when(
              SGENDER == 1 ~ 1, # girl
              SGENDER == 0 ~ 0, # boy
              )) %>%
             # Chile: school administration
              mutate(dep = case_when(
                COUNTRY == 'CHL' & IDSTRATE == 1 ~ 1, # Municipal
                COUNTRY == 'CHL' & IDSTRATE == 3 ~ 2, # Subvencionado
                COUNTRY == 'CHL' & IDSTRATE == 2 ~ 3  # Privado
                )) %>%
              mutate(mun = if_else(dep == 1, 1, 0)) %>%
              mutate(sub = if_else(dep == 2, 1, 0)) %>%
              mutate(pri = if_else(dep == 3, 1, 0)) %>%         
            # Latinoamerican test
            mutate(y01 = if_else(LS2T01 == 4, 1, 0)) %>%
            mutate(y02 = if_else(LS2T02 == 1, 1, 0)) %>%
            mutate(y03 = if_else(LS2T03 == 3, 1, 0)) %>%
            mutate(y04 = if_else(LS2T04 == 4, 1, 0)) %>%
            mutate(y05 = if_else(LS2T05 == 1, 1, 0)) %>%
            mutate(y06 = if_else(LS2T06 == 4, 1, 0)) %>%
            mutate(y07 = if_else(LS2T07 == 3, 1, 0)) %>%
            mutate(y08 = if_else(LS2T08 == 3, 1, 0)) %>%
            mutate(y09 = if_else(LS2T09 == 2, 1, 0)) %>%
            mutate(y10 = if_else(LS2T10 == 1, 1, 0)) %>%
            mutate(y11 = if_else(LS2T11 == 1, 1, 0)) %>%
            mutate(y12 = if_else(LS2T12 == 4, 1, 0)) %>%
            mutate(y13 = if_else(LS2T13 == 2, 1, 0)) %>%
            mutate(y14 = if_else(LS2T14 == 1, 1, 0)) %>%
            mutate(y15 = if_else(LS2T15 == 4, 1, 0)) %>%
            mutate(y16 = if_else(LS2T16 == 2, 1, 0)) %>%
            dplyr::select(
            id_p, COUNTRY, IDCNTRY, IDSTUD, IDSCHOOL, 
            TOTWGTS, JKZONES, JKREPS,
            sex, dep, mun, sub, pri, LS2T01:LS2T16, y01:y16) %>%
            mutate(test_sum = ilsa::sum_score(
              y01,y02,y03,y04,
              y05,y06,y07,y08,
              y09,y10,y11,y12,
              y12,y14,y15,y16
              )) %>%
            dplyr::left_join(.,
            data_cov, by = c('IDCNTRY', 'IDSTUD', 'IDSCHOOL')) %>%
            dplyr::glimpse()   
```

#block[
```
Rows: 5,173
Columns: 55
$ id_p     <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18…
$ COUNTRY  <chr> "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL"…
$ IDCNTRY  <dbl+lbl> 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 15…
$ IDSTUD   <dbl> 10010201, 10010202, 10010203, 10010204, 10010205, 10010206, 1…
$ IDSCHOOL <dbl+lbl> 1001, 1001, 1001, 1001, 1001, 1001, 1001, 1001, 1001, 100…
$ TOTWGTS  <dbl+lbl> 63.31969, 63.31969, 63.31969, 63.31969, 63.31969, 63.3196…
$ JKZONES  <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, …
$ JKREPS   <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, …
$ sex      <dbl> 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, NA, 1, 0, 1, …
$ dep      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
$ mun      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
$ sub      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
$ pri      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
$ LS2T01   <dbl+lbl>  4,  4,  4,  2,  2,  4,  3,  4,  4,  4,  4,  2,  4,  4,  …
$ LS2T02   <dbl+lbl>  1, NA,  1,  3,  1,  1,  1,  1,  4,  1,  1,  1,  1, NA,  …
$ LS2T03   <dbl+lbl> 3, 2, 3, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, …
$ LS2T04   <dbl+lbl> 4, 4, 4, 4, 4, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, …
$ LS2T05   <dbl+lbl> 4, 1, 3, 3, 1, 4, 1, 1, 4, 1, 1, 4, 3, 2, 1, 4, 2, 3, 1, …
$ LS2T06   <dbl+lbl> 4, 2, 2, 1, 3, 3, 3, 4, 4, 4, 4, 4, 1, 1, 4, 1, 3, 3, 1, …
$ LS2T07   <dbl+lbl> 3, 4, 3, 2, 4, 2, 4, 4, 3, 2, 4, 3, 2, 4, 4, 4, 3, 4, 2, …
$ LS2T08   <dbl+lbl> 3, 3, 2, 2, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, …
$ LS2T09   <dbl+lbl> 4, 2, 4, 4, 2, 2, 4, 4, 4, 2, 4, 4, 2, 3, 4, 2, 2, 3, 2, …
$ LS2T10   <dbl+lbl>  1, NA,  1,  3,  3,  1,  2,  2,  2,  1,  2,  4,  1, NA,  …
$ LS2T11   <dbl+lbl>  1,  2,  4,  2,  3,  1,  3,  1,  1,  1,  1,  1,  1,  1,  …
$ LS2T12   <dbl+lbl> 3, 1, 1, 2, 4, 4, 2, 4, 2, 4, 4, 4, 2, 4, 4, 4, 1, 4, 1, …
$ LS2T13   <dbl+lbl> 2, 1, 2, 3, 2, 2, 2, 2, 4, 2, 2, 2, 2, 1, 1, 1, 3, 1, 2, …
$ LS2T14   <dbl+lbl> 1, 2, 1, 2, 1, 1, 3, 1, 1, 2, 1, 2, 1, 1, 4, 1, 4, 2, 1, …
$ LS2T15   <dbl+lbl> 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 4, 4, …
$ LS2T16   <dbl+lbl> 3, 2, 2, 4, 2, 2, 2, 2, 2, 2, 1, 4, 2, 1, 2, 2, 3, 2, 2, …
$ y01      <dbl> 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, NA, 0, 0, 1, 0, …
$ y02      <dbl> 1, NA, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, NA, 0, 1, 1, 1, 1, 1,…
$ y03      <dbl> 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0…
$ y04      <dbl> 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1…
$ y05      <dbl> 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0…
$ y06      <dbl> 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0…
$ y07      <dbl> 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0…
$ y08      <dbl> 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1…
$ y09      <dbl> 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0…
$ y10      <dbl> 1, NA, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, NA, 1, 1, 0, 1, 0, 1,…
$ y11      <dbl> 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, NA, 1, 1, 1, …
$ y12      <dbl> 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0…
$ y13      <dbl> 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0…
$ y14      <dbl> 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1…
$ y15      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0…
$ y16      <dbl> 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1…
$ test_sum <dbl> 11, 7, 9, 3, 11, 12, 5, 13, 9, 14, 12, 10, 11, 9, 10, 12, 5, …
$ NWLCIV   <dbl+lbl> 154.5731, 145.1441, 144.8098, 133.0771, 160.5530, 154.487…
$ KNOWLMLE <dbl+lbl>        NA,  93.71446,  89.42393,        NA,        NA,   …
$ PV1CIV   <dbl+lbl> 547.3724, 404.3672, 505.3120, 321.2980, 530.5482, 461.148…
$ PV2CIV   <dbl+lbl> 529.4967, 464.3032, 431.7064, 339.1737, 545.2694, 526.342…
$ PV3CIV   <dbl+lbl> 521.0847, 454.8396, 481.1273, 330.7616, 494.7969, 453.788…
$ PV4CIV   <dbl+lbl> 496.9000, 428.5519, 453.7881, 286.5982, 559.9905, 494.796…
$ PV5CIV   <dbl+lbl> 577.8661, 408.5732, 497.9515, 319.1950, 596.7933, 439.067…
$ ses      <dbl> 1.16665222, -1.17623742, 0.03919470, -0.77188999, -0.49257816…
$ edu      <dbl> 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
```

]
]
= Modelo Rasch como modelo mixto generalizado
<modelo-rasch-como-modelo-mixto-generalizado>
- Vamos a recurrir a una forma diferente de parametrización del modelo anterior, el cual debiera ser más intuitiva para que podamos interpretar en que consiste el modelo Rasch. En términos generales, un modelo Rasch es una regresión logistica, en que los ítems condicionan (i.e., predicen) a las respuestas. Pero, con un detalle, que las personas son incluidas como efecto aleatorio en el modo de estimación que hemos elegido (#emph[Marginal Maximum Likelihood];). Es decir, es un modelo mixto o modelo multinivel generalizado, en que empleamos a items como efectos fijos, y a personas como efectos aleatorios. Esta idea se encuentra desarrollada en de Boeck et al.~(2011), en la cual se ilustra como ajustar modelos Rasch, empleando a la librería `lme4`.

- En nuestro caso vamos a emplear una librería llamada `library(PLmixed)`, la cual puede ajustar estos modelos, pero posee tiempos de estimación menores.

#block[
#callout(
body: 
[
Los modelos mixtos generalizados pueden tener tiempos de estimación mayores en contraste a modelos más simples como los modelos de regresión lineal. Este tiempo depende de las librerías disponibles. De esta forma, si quieren reproducir los resultados ilustrados en este documento, el tiempo que se demore en completar todos los pasos puede ser más de lo esperado.

]
, 
title: 
[
Advertencia
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
- En el modelo que vamos a ajustar, $y_(i p)$ es una variable dictotómica, y como tal, la podemos condicionar en un modelo de regresión logística.

- $delta_i$ son dificultades, estas expresan la relación entre un ítem, y que las respuestas sobre $y_(i p)$ sean clasificadas como respuestas correctas (valor uno) en incorrecta (valor cero).

- Si emplearamos un modelo mixto, es decir un modelo multinivel, podemos obtener a todos los términos que incluye el modelo Rasch.

- Si tuvieramos a los datos en un formato #emph[apilado] (i.e., #emph[stacked];) (Hoffman, 2015), donde cada fila es una respuesta, y cada 16 filas, tenemos a las respuestas de una misma persona podriamos ajustar el model Rasch como un modelo mixto generalizado.

$ l n [P r (y_(i p) = 1)] = delta_i + theta p $

- Vamos a preparar a los datos en este formato para ajustar el modelo descrito en la ecuación anterior, con una regresión logística, en particular con una modelo de regresión logística multinivel.

#block[
#callout(
body: 
[
No son muchas las referencias que incluyan una nomenclatura para hablar del formato de la base de datos. Excepciones son Hoffman (2015) y Singer & Willet (2003). Estos libros son acerca de modelos longitudinales los cuales tradicionalmente consisten en modelos donde tenemos observaciones repetidas sobre las mismas personas, y donde tradicionalmente se separa la varianza entre las ocasiones, y las personas. En este tipo de estudios es común variar el formato de la base de datos de #emph[apilado] (#emph[stacked];) a #emph[multivariado] (#emph[wide];). El analisis de datos de ítems, bajo el marco general de variables latentes, y de IRT, es común que este procedimiento tambien sea empleado, de modo de emplear rutinas comunes a los analisis multinivel, o rutinas de análisis de ecuaciones estructurales.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Datos apilados
<datos-apilados>
- Tradicionalmente los datos en estudios de gran escala, se encuentra en formato #emph[multivariado] (i.e.~#emph[wide];):

```r
set.seed(20240404)
data.frame(
persons = 1:5,
y1 = sample(0:1, 5, replace = TRUE),
y2 = sample(0:1, 5, replace = TRUE),
y3 = sample(0:1, 5, replace = TRUE),
y4 = sample(0:1, 5, replace = TRUE)
) %>%
knitr::kable()
```

#table(
  columns: 5,
  align: (right,right,right,right,right,),
  table.header([persons], [y1], [y2], [y3], [y4],),
  table.hline(),
  [1], [0], [0], [0], [1],
  [2], [1], [0], [1], [1],
  [3], [1], [1], [1], [0],
  [4], [0], [1], [1], [1],
  [5], [0], [0], [1], [1],
)
- Sin embargo, para ajustar el modelo que estamos proponiendo necesitamos un formato #emph[apilado] (i.e., #emph[stacked];)

```r
set.seed(20240404)
data.frame(
persons = 1:5,
y1 = sample(0:1, 5, replace = TRUE),
y2 = sample(0:1, 5, replace = TRUE),
y3 = sample(0:1, 5, replace = TRUE),
y4 = sample(0:1, 5, replace = TRUE)
) %>%
tidyr::pivot_longer(
cols = y1:y4,
names_to = 'items',
values_to = 'y'
) %>%
knitr::kable()
```

#table(
  columns: 3,
  align: (right,left,right,),
  table.header([persons], [items], [y],),
  table.hline(),
  [1], [y1], [0],
  [1], [y2], [0],
  [1], [y3], [0],
  [1], [y4], [1],
  [2], [y1], [1],
  [2], [y2], [0],
  [2], [y3], [1],
  [2], [y4], [1],
  [3], [y1], [1],
  [3], [y2], [1],
  [3], [y3], [1],
  [3], [y4], [0],
  [4], [y1], [0],
  [4], [y2], [1],
  [4], [y3], [1],
  [4], [y4], [1],
  [5], [y1], [0],
  [5], [y2], [0],
  [5], [y3], [1],
  [5], [y4], [1],
)
- Vamos a cambiar el formato original de los datos al formato que estamos proponiendo. Es decir que vamos a trasponer las respuestas que estan a lo ancho, y las vamos a relocalizar a lo largo.

#block[
```r
data_stacked <- data_model %>%
dplyr::select(id_p, y01:y16) %>%
tidyr::pivot_longer(
cols = y01:y16,
names_to = 'items',
values_to = 'y'
) %>%
dplyr::glimpse()
```

#block[
```
Rows: 82,768
Columns: 3
$ id_p  <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2…
$ items <chr> "y01", "y02", "y03", "y04", "y05", "y06", "y07", "y08", "y09", "…
$ y     <dbl> 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, NA, 0, 1, 1, …
```

]
]
- Ahora, nuestra base de datos analizable se ve de la siguiente forma, para una seleccion de tres casos, y una muestra de 4 items.

```r
data_stacked %>%
dplyr::filter(id_p %in% c(1,3,4)) %>%
dplyr::slice_sample(n = 4, by = id_p) %>%
knitr::kable()
```

#table(
  columns: 3,
  align: (right,left,right,),
  table.header([id\_p], [items], [y],),
  table.hline(),
  [1], [y13], [1],
  [1], [y16], [0],
  [1], [y04], [1],
  [1], [y15], [1],
  [3], [y07], [1],
  [3], [y04], [1],
  [3], [y15], [1],
  [3], [y09], [0],
  [4], [y16], [0],
  [4], [y12], [0],
  [4], [y11], [0],
  [4], [y09], [0],
)
== Ajustar modelo
<ajustar-modelo>
- Para ajustar el modelo anterior, escribimos el siguiente código:

#block[
```r
library(PLmixed)
rasch_mlm <- PLmixed(
  # formula que expresa el modelo
  formula = y ~ -1 + items + (1 | id_p),
  # indicar la función de enlace
  family = binomial,
  # indicar los datos que serán empleados
  data = data_stacked
)
```

]
- Con el código anterior, obtenemos los siguientes resultados.

#block[
```r
library(PLmixed)
rasch_mlm <- PLmixed(
  formula = y ~ -1 + items + (1 | id_p),
  family = binomial,
  data = data_stacked
)
```

#block[
```

 Iteration Number: 1
                                   
```

]
```r
summary(rasch_mlm)
```

#block[
```
Profile-based Mixed Effect Model Fit With PLmixed Using lme4 
Formula:  y ~ -1 + items + (1 | id_p) 
Data:  data_stacked 
 Family: binomial  ( logit )

      AIC       BIC    logLik  deviance  df.resid 
 92630.31  92788.67 -46298.15  81480.53     82042 

Scaled residuals: 
    Min      1Q  Median      3Q     Max 
-2.7644 -0.9098  0.4320  0.8191  2.5275 

Random effects:
 Groups Name        Variance Std.Dev.
 id_p   (Intercept) 1.136    1.066   
Number of obs: 82059, groups:  id_p, 5172
 
Fixed effects: 
             Beta      SE   z value   Pr(>|z|)
itemsy01 -0.15094 0.03445  -4.38145  1.179e-05
itemsy02  1.42118 0.03881  36.61923 1.414e-293
itemsy03  2.11117 0.04481  47.10961  0.000e+00
itemsy04  2.27875 0.04685  48.64375  0.000e+00
itemsy05  0.23428 0.03438   6.81484  9.437e-12
itemsy06 -0.74153 0.03584 -20.69022  4.243e-95
itemsy07 -0.86739 0.03607 -24.04821 8.716e-128
itemsy08  1.20847 0.03746  32.26196 2.391e-228
itemsy09  0.33556 0.03451   9.72337  2.397e-22
itemsy10 -0.24217 0.03472  -6.97586  3.040e-12
itemsy11  0.00147 0.03435   0.04279  9.659e-01
itemsy12 -0.69414 0.03545 -19.57944  2.315e-85
itemsy13  0.37267 0.03468  10.74619  6.176e-27
itemsy14  0.71181 0.03545  20.07890  1.129e-89
itemsy15  1.62165 0.04026  40.27526  0.000e+00
itemsy16  1.14996 0.03722  30.89340 1.465e-209

lme4 Optimizer:  bobyqa 
Optim Optimizer:  NA 
Optim Iterations:  1 
Estimation Time:  0.75 minutes 
```

]
]
- Notese que los $delta_i$ de este modelo, es decir, los efectos fijos asociados a los ítems, nos indican la relación entre el ítem, y las respuestas correctas.

- Dicho de otro modo, cuando un ítem tiene un coeficiente positivo, significa que hay una relación positiva con observar respuestas correctas; por el contrario, si el coeficiente es negativo, nos indica que respecto a este ítem, hay una relación negativa con las respuestas correctas.

- Lo anterior implica que las $delta_i$ no están parametrizados como "dificultades", sino como "facilidades". No obstante, estos estimados pueden ser interpretados como estimados de #emph[locación] de los items.

- Items de mayor coeficiente son items más fáciles, e ítems de menor punto estimado son más difícles. Con esta información podemos ordenar las preguntas del test empleado, y tener una noción de como contestan el conjunto de individuos que participó de la prueba.

- Un aspecto no trivial de la forma de escribir el código es la "supresión" del intercepto. Esto lo logramos mediante la inclusión del `-1` antes de incluir a la columna `items`. Por su parte, la variable `items`, como contiene texto, esta siendo interpretada por la librería como un conjunto de factores, y está siendo ingresada al modelo como un conjunto de variables #emph[dummy];, de valor 0 cuando está ausente, y valor uno, cuando en la fila se encuentra registrada la respuesta al ítem respectivo.

- 'formula = y \~ #strong[\-1] + items + (1 | id\_p)'

  - incluimos a `-1` para remover de la estimación al intercepto.
  - el modelo se encuentra identificado, porque tenemos una media cero y una varianza libre.

- 'formula = y \~ -1 + #strong[items] + (1 | id\_p)'

  - #strong[items] esta siendo ingresado al modelo como un conjunto de variables dummy.
  - cuando reparametricemos el modelo, vamos a incluir de forma explícita a los ítems, como variables dummy.

== Reparametrizando a los deltas
<reparametrizando-a-los-deltas>
- Podemos reparametrizar el modelo anterior si creamos variables dummy, donde cada item toma un valor 0 cuando no se observa al ítem, y un valor -1 cuando la respuesta está indexada al ítem.

- El objetivo de esta reparametrización es ajustar el modelo Rasch como tradicionalmente lo ajustan los software especializados como `TAM`, `Conquest`, y otros software.

- Es decir, queremos convertir el siguiente modelo $l n [P r (y_(i p) = 1)] = delta_i + theta p$, en otra expresión equivalente, donde los $delta_i$ sean estimados como dificultades. En otras palabras, queremos ajustar al siguiente modelo:

$ l n [P r (y_(i p) = 1)] = theta p - delta_i $

#block[
```r
data_stacked <- data_model %>%
dplyr::select(id_p, y01:y16) %>%
tidyr::pivot_longer(
cols = y01:y16,
names_to = 'items',
values_to = 'y'
) %>%
mutate(u01 = dplyr::if_else(items == 'y01', -1, 0)) %>%
mutate(u02 = dplyr::if_else(items == 'y02', -1, 0)) %>%
mutate(u03 = dplyr::if_else(items == 'y03', -1, 0)) %>%
mutate(u04 = dplyr::if_else(items == 'y04', -1, 0)) %>%
mutate(u05 = dplyr::if_else(items == 'y05', -1, 0)) %>%
mutate(u06 = dplyr::if_else(items == 'y06', -1, 0)) %>%
mutate(u07 = dplyr::if_else(items == 'y07', -1, 0)) %>%
mutate(u08 = dplyr::if_else(items == 'y08', -1, 0)) %>%
mutate(u09 = dplyr::if_else(items == 'y09', -1, 0)) %>%
mutate(u10 = dplyr::if_else(items == 'y10', -1, 0)) %>%
mutate(u11 = dplyr::if_else(items == 'y11', -1, 0)) %>%
mutate(u12 = dplyr::if_else(items == 'y12', -1, 0)) %>%
mutate(u13 = dplyr::if_else(items == 'y13', -1, 0)) %>%
mutate(u14 = dplyr::if_else(items == 'y14', -1, 0)) %>%
mutate(u15 = dplyr::if_else(items == 'y15', -1, 0)) %>%
mutate(u16 = dplyr::if_else(items == 'y16', -1, 0)) %>%
dplyr::glimpse()
```

#block[
```
Rows: 82,768
Columns: 19
$ id_p  <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2…
$ items <chr> "y01", "y02", "y03", "y04", "y05", "y06", "y07", "y08", "y09", "…
$ y     <dbl> 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, NA, 0, 1, 1, …
$ u01   <dbl> -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0,…
$ u02   <dbl> 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0,…
$ u03   <dbl> 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0,…
$ u04   <dbl> 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,…
$ u05   <dbl> 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1,…
$ u06   <dbl> 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u07   <dbl> 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u08   <dbl> 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u09   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u10   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u11   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u12   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u13   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, …
$ u14   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, …
$ u15   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, …
$ u16   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, …
```

]
]
- Ahora, nuestra base de datos analizable posee una variable dummy por cada ítem.

```r
data_stacked %>%
dplyr::filter(id_p %in% c(1)) %>%
knitr::kable()
```

#table(
  columns: (6.41%, 7.69%, 3.85%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%, 5.13%),
  align: (right,left,right,right,right,right,right,right,right,right,right,right,right,right,right,right,right,right,right,),
  table.header([id\_p], [items], [y], [u01], [u02], [u03], [u04], [u05], [u06], [u07], [u08], [u09], [u10], [u11], [u12], [u13], [u14], [u15], [u16],),
  table.hline(),
  [1], [y01], [1], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y02], [1], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y03], [1], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y04], [1], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y05], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y06], [1], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y07], [1], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y08], [1], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0], [0],
  [1], [y09], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0], [0],
  [1], [y10], [1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0], [0],
  [1], [y11], [1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0], [0],
  [1], [y12], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0], [0],
  [1], [y13], [1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0], [0],
  [1], [y14], [1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0], [0],
  [1], [y15], [1], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1], [0],
  [1], [y16], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [-1],
)
- Con estos nuevos datos analizables podemos ajustar el modelo Rasch con su parametrización tradicional

- Ajustamos nuestro código anterior de forma respectiva, ahora incluyendo a cada uno de los ítems como variable dummy:

#block[
```r
library(PLmixed)
rasch_rep <- PLmixed(
  formula = y ~ -1 + 
  u01 + u02 + u03 + u04 + u05 +
  u06 + u07 + u08 + u09 + u10 +
  u11 + u12 + u13 + u14 + u15 +
  u16 +
  (1 | id_p),
  family = binomial,
  data = data_stacked
)
```

#block[
```

 Iteration Number: 1
                                   
```

]
]
- Con el código anterior obtenemos los siguientes resultados:

#block[
```r
summary(rasch_rep)
```

#block[
```
Profile-based Mixed Effect Model Fit With PLmixed Using lme4 
Formula:  y ~ -1 + u01 + u02 + u03 + u04 + u05 + u06 + u07 + u08 + u09 +      u10 + u11 + u12 + u13 + u14 + u15 + u16 + (1 | id_p) 
Data:  data_stacked 
 Family: binomial  ( logit )

      AIC       BIC    logLik  deviance  df.resid 
 92630.31  92788.67 -46298.15  81480.53     82042 

Scaled residuals: 
    Min      1Q  Median      3Q     Max 
-2.7644 -0.9098  0.4320  0.8191  2.5275 

Random effects:
 Groups Name        Variance Std.Dev.
 id_p   (Intercept) 1.136    1.066   
Number of obs: 82059, groups:  id_p, 5172
 
Fixed effects: 
         Beta      SE   z value   Pr(>|z|)
u01  0.150931 0.03446   4.38016  1.186e-05
u02 -1.421190 0.03883 -36.60219 2.639e-293
u03 -2.111175 0.04479 -47.13487  0.000e+00
u04 -2.278757 0.04684 -48.64635  0.000e+00
u05 -0.234281 0.03439  -6.81267  9.580e-12
u06  0.741525 0.03585  20.68462  4.765e-95
u07  0.867380 0.03608  24.04041 1.052e-127
u08 -1.208482 0.03744 -32.27475 1.582e-228
u09 -0.335568 0.03452  -9.71986  2.481e-22
u10  0.242167 0.03470   6.97866  2.980e-12
u11 -0.001475 0.03435  -0.04295  9.657e-01
u12  0.694140 0.03545  19.57827  2.369e-85
u13 -0.372678 0.03468 -10.74700  6.122e-27
u14 -0.711811 0.03545 -20.08127  1.076e-89
u15 -1.621647 0.04026 -40.28033  0.000e+00
u16 -1.149961 0.03721 -30.90069 1.169e-209

lme4 Optimizer:  bobyqa 
Optim Optimizer:  NA 
Optim Iterations:  1 
Estimation Time:  0.78 minutes 
```

]
]
== Deltas comparados
<deltas-comparados>
- Si comparamos los efectos fijos de ambos modelos, se puede ver que los puntos estimados son los inversos del otro.

- En la primera especificación, el modelo produce puntos estimados en "facilidades" para los ítems. Es decir, a mayor coeficiente el ítem es más fácil.

- En la segunda especificación, los coeficientes producidos están en "dificultades" (i.e., mayor valor, ítem es más dificil, más distante del cero de referencia del modelo).

- Los puntos estimados en cada caso son equivalentes.

```r
table_1 <- coef(rasch_mlm) %>%
purrr::pluck('id_p') %>%
dplyr::select(-`(Intercept)`) %>%
unique() %>%
tidyr::pivot_longer(
cols = names(.),
names_to = 'items',
values_to = 'param_1'
)

table_2 <- coef(rasch_rep) %>%
purrr::pluck('id_p') %>%
dplyr::select(u01:u16) %>%
unique() %>%
tidyr::pivot_longer(
cols = u01:u16,
names_to = 'dummy',
values_to = 'param_2'
)

dplyr::bind_cols(table_1,table_2) %>%
mutate(dif = abs(param_1) - abs(param_2)) %>%
knitr::kable(., digits = 2)
```

#table(
  columns: 5,
  align: (left,right,left,right,right,),
  table.header([items], [param\_1], [dummy], [param\_2], [dif],),
  table.hline(),
  [itemsy01], [-0.15], [u01], [0.15], [0],
  [itemsy02], [1.42], [u02], [-1.42], [0],
  [itemsy03], [2.11], [u03], [-2.11], [0],
  [itemsy04], [2.28], [u04], [-2.28], [0],
  [itemsy05], [0.23], [u05], [-0.23], [0],
  [itemsy06], [-0.74], [u06], [0.74], [0],
  [itemsy07], [-0.87], [u07], [0.87], [0],
  [itemsy08], [1.21], [u08], [-1.21], [0],
  [itemsy09], [0.34], [u09], [-0.34], [0],
  [itemsy10], [-0.24], [u10], [0.24], [0],
  [itemsy11], [0.00], [u11], [0.00], [0],
  [itemsy12], [-0.69], [u12], [0.69], [0],
  [itemsy13], [0.37], [u13], [-0.37], [0],
  [itemsy14], [0.71], [u14], [-0.71], [0],
  [itemsy15], [1.62], [u15], [-1.62], [0],
  [itemsy16], [1.15], [u16], [-1.15], [0],
)
#block[
#callout(
body: 
[
`param_1` contiene los estimados de la primera parametrización, donde los ítems son ingresados como dummy, donde cada ítem observado es 1, y cuando la respuesta observada pertenece a los otros ítems, es codificado como cero. `param_2` contiene a las estimaciones del modelo donde los delta son parametrizados como dificultades, donde un ítem observado es -1, y cuando la respuesta observada pertenece a los otros ítems es codificada como cero.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
= Modelo Rasch ajustado con libreria especializada
<modelo-rasch-ajustado-con-libreria-especializada>
- Los tiempos de estimación con una libreria no especializada pueden ser muy mayores, solo porque el procedimiento que ejecuta los cálculos podría no estar optimizado. A continuación emplearemos a la librería especializada, la librería #strong[TAM];.

- Vamos a ajustar el modelo en 4 pasos

  - Vamos a crear una matriz de respuesta, la cual solo incluye a los ítems.

  - Vamos a separar los datos analizables a una lista de valores que identifica a las personas.

    - Es decir, un vector que contiene un indentificador único de los participantes.

    - Este paso nos servirá para extraer realizaciones de $theta_p$, y luego agregar estas realizaciones (los puntajes IRT) a la base de datos original.

  - Vamos a emplear a la funnción `TAM::tam.mml()` para ajustar un modelo Rasch con MML.

  - Finalmente, vamos a desplegar los resultados obtenidos con la función `summary`.

#block[
```r
# -----------------------------------------------
# response data
# -----------------------------------------------

data_resp <- data_model %>%
             dplyr::select(y01:y16)

# -----------------------------------------------
# unique identifier
# -----------------------------------------------

id_p_list <- data_model %>%
             dplyr::select(id_p) %>%
             dplyr::pull()

# -----------------------------------------------
# fit model
# -----------------------------------------------

rasch_tam <- TAM::tam.mml(
             resp = data_resp, 
             pid = id_p_list,
             irtmodel = "1PL", 
             verbose = FALSE
             )

# -----------------------------------------------
# results
# -----------------------------------------------

summary(rasch_tam)
```

#block[
```
------------------------------------------------------------
TAM 4.3-25 (2025-08-28 18:03:24) 
R version 4.5.1 (2025-06-13) aarch64, darwin20 | nodename=musashi.local | login=root 

Date of Analysis: 2026-08-25 02:34:07.06779 
Time difference of 0.137336 secs
Computation time: 0.137336 

Multidimensional Item Response Model in TAM 

IRT Model: 1PL
Call:
TAM::tam.mml(resp = data_resp, irtmodel = "1PL", pid = id_p_list, 
    verbose = FALSE)

------------------------------------------------------------
Number of iterations = 21 
Numeric integration with 21 integration points

Deviance = 92516.54 
Log likelihood = -46258.27 
Number of persons = 5173 
Number of persons used = 5172 
Number of items = 16 
Number of estimated parameters = 17 
    Item threshold parameters = 16 
    Item slope parameters = 0 
    Regression parameters = 0 
    Variance/covariance parameters = 1 

AIC = 92551  | penalty=34    | AIC=-2*LL + 2*p 
AIC3 = 92568  | penalty=51    | AIC3=-2*LL + 3*p 
BIC = 92662  | penalty=145.37    | BIC=-2*LL + log(n)*p 
aBIC = 92608  | penalty=91.33    | aBIC=-2*LL + log((n-2)/24)*p  (adjusted BIC) 
CAIC = 92679  | penalty=162.37    | CAIC=-2*LL + [log(n)+1]*p  (consistent AIC) 
AICc = 92551  | penalty=34.12    | AICc=-2*LL + 2*p + 2*p*(p+1)/(n-p-1)  (bias corrected AIC) 
GHP = 0.56393     | GHP=( -LL + p ) / (#Persons * #Items)  (Gilula-Haberman log penalty) 

------------------------------------------------------------
EAP Reliability
[1] 0.755
------------------------------------------------------------
Covariances and Variances
      [,1]
[1,] 1.159
------------------------------------------------------------
Correlations and Standard Deviations (in the diagonal)
      [,1]
[1,] 1.077
------------------------------------------------------------
Regression Coefficients
     [,1]
[1,]    0
------------------------------------------------------------
Item Parameters -A*Xsi
   item    N     M xsi.item AXsi_.Cat1 B.Cat1.Dim1
1   y01 5122 0.469    0.150      0.150           1
2   y02 5129 0.762   -1.422     -1.422           1
3   y03 5160 0.852   -2.113     -2.113           1
4   y04 5154 0.870   -2.281     -2.281           1
5   y05 5158 0.547   -0.235     -0.235           1
6   y06 5056 0.355    0.740      0.740           1
7   y07 5139 0.331    0.866      0.866           1
8   y08 5150 0.728   -1.209     -1.209           1
9   y09 5151 0.567   -0.336     -0.336           1
10  y10 5067 0.451    0.241      0.241           1
11  y11 5137 0.500   -0.002     -0.002           1
12  y12 5133 0.363    0.693      0.693           1
13  y13 5118 0.574   -0.373     -0.373           1
14  y14 5117 0.640   -0.712     -0.712           1
15  y15 5136 0.791   -1.623     -1.623           1
16  y16 5132 0.718   -1.150     -1.150           1

Item Parameters in IRT parameterization
   item alpha   beta
1   y01     1  0.150
2   y02     1 -1.422
3   y03     1 -2.113
4   y04     1 -2.281
5   y05     1 -0.235
6   y06     1  0.740
7   y07     1  0.866
8   y08     1 -1.209
9   y09     1 -0.336
10  y10     1  0.241
11  y11     1 -0.002
12  y12     1  0.693
13  y13     1 -0.373
14  y14     1 -0.712
15  y15     1 -1.623
16  y16     1 -1.150
```

]
]
== Resultados obtenidos
<resultados-obtenidos>
- Como `TAM` es una librería especializada en modelos IRT de tipo Rasch, no solo nos provee de los resultados del modelo mixto, sino que acompaña a la salida de otros indicadores.

- Un resultado que podemos destacar es el #strong[EAP Reliability];. Este indicador es similar al indicador de intra clase de los modelos multinivel, y nos indica que tan separadas están las medias latentes del modelo. Es decir, que tan distintas son los $theta_p$ que el modelo puede generar. Comúnmente a este tipo de indicador se le llama #emph[person separation reliability] (Verhavert et al, 2018; Adams, 2005).

- Medias latentes más separadas, son considerandos puntajes más precisos (i.e., más confiables), ya que significa que, si ordeno a todas las personas en un ranking, necesito moverme menos posiciones en el ranking para indicar que dos personas del ranking ordenado son distintas por sobre la incertidumbre asociada a $theta_p$.

- Estos indicadores de confiabilidad global los podemos obtener con los siguientes códigos

```r
# get wle estimates
tam_wle  <- TAM::tam.wle(rasch_tam, progress = FALSE)

# get objects
theta_wle  <- tam_wle$theta
theta_se   <- tam_wle$error

# create table
reliability_table <- data.frame(
index = c('WLE', 'EAP'),
value = c(TAM::WLErel(theta_wle,theta_se),
TAM::EAPrel(theta_wle,theta_se))
)

# display table
knitr::kable(reliability_table, digits = 2)
```

#table(
  columns: 2,
  align: (left,right,),
  table.header([index], [value],),
  table.hline(),
  [WLE], [0.71],
  [EAP], [0.77],
)
- Una omisión de esta salida son los errores estándar de los efectos fijos. Los errores estandar de los $delta_i$ (i.e., deltas) se pueden obtener extrayendo elementos que se encuentran dentro del objeto de resultados que hemos generado con la librería TAM. A continuación, extraemos los puntos estimados de los delta que genera TAM.

```r
rasch_tam %>%
purrr::pluck('xsi') %>%
knitr::kable(., digits = 2)
```

#table(
  columns: 3,
  align: (left,right,right,),
  table.header([], [xsi], [se.xsi],),
  table.hline(),
  [y01], [0.15], [0.03],
  [y02], [-1.42], [0.04],
  [y03], [-2.11], [0.04],
  [y04], [-2.28], [0.04],
  [y05], [-0.23], [0.03],
  [y06], [0.74], [0.03],
  [y07], [0.87], [0.03],
  [y08], [-1.21], [0.03],
  [y09], [-0.34], [0.03],
  [y10], [0.24], [0.03],
  [y11], [0.00], [0.03],
  [y12], [0.69], [0.03],
  [y13], [-0.37], [0.03],
  [y14], [-0.71], [0.03],
  [y15], [-1.62], [0.04],
  [y16], [-1.15], [0.03],
)
- Si comparamos los deltas generados por TAM, estos son equivalentes a los obtenidos con la libreria `PLmixed`, bajo la misma parametrización.

```r
table_1_plmixed <- coef(rasch_rep) %>%
purrr::pluck('id_p') %>%
dplyr::select(u01:u16) %>%
unique() %>%
tidyr::pivot_longer(
cols = u01:u16,
names_to = 'item',
values_to = 'PLmixed_delta'
)

table_2_tam <- rasch_tam %>%
purrr::pluck('xsi') %>%
dplyr::select(xsi) %>%
rename(tam_delta = xsi)

dplyr::bind_cols(table_1_plmixed,table_2_tam) %>%
mutate(dif = abs(PLmixed_delta) - abs(tam_delta)) %>%
knitr::kable(., digits = 2)
```

#table(
  columns: 4,
  align: (left,right,right,right,),
  table.header([item], [PLmixed\_delta], [tam\_delta], [dif],),
  table.hline(),
  [u01], [0.15], [0.15], [0],
  [u02], [-1.42], [-1.42], [0],
  [u03], [-2.11], [-2.11], [0],
  [u04], [-2.28], [-2.28], [0],
  [u05], [-0.23], [-0.23], [0],
  [u06], [0.74], [0.74], [0],
  [u07], [0.87], [0.87], [0],
  [u08], [-1.21], [-1.21], [0],
  [u09], [-0.34], [-0.34], [0],
  [u10], [0.24], [0.24], [0],
  [u11], [0.00], [0.00], [0],
  [u12], [0.69], [0.69], [0],
  [u13], [-0.37], [-0.37], [0],
  [u14], [-0.71], [-0.71], [0],
  [u15], [-1.62], [-1.62], [0],
  [u16], [-1.15], [-1.15], [0],
)
- Con esta ilustración podemos defender la idea de que un modelo Rasch es esencialmente una regresión logística, en el que los ítems predicen a las respuestas correctas observadas, donde además hemos incluido un término aleatorio para las personas. Rasch, bajo MML, es un modelo mixto generalizado para variables dicotómicas.

= Interpretación de los resultados
<interpretación-de-los-resultados>
== Interpretación de los delta (#emph[items side];)
<interpretación-de-los-delta-items-side>
- Condicional a cómo haya sido parametrizado el modelo, podemos interpretar a los $delta_i$, como dificultad o como facilidad. En términos abstractos que tan común es que observemos a $P r (y_i = 1)$, condicional a un ítem.

- El significado de $P r (y_i = 1)$ se desprende del contenido del instrumento. Mayor $P r (y_i = 1)$ para un ítem puede ser más conocimiento, mayor acuerdo, más frecuencia, u otra expresión de un atributo de interés.

- En este ejemplo, mayor $P r (y_i = 1)$, es mayor conocimiento cívico, i.e., #emph[mayor habilidad];. Esta última interpretación aplica para instrumentos tipo test donde hay respuestas correctas o incorrectas.

- Sin embargo, si el contenido del instrumento fuera otro, como un intrumento de actitudes, creencias, adhesión a normas, autoreporte de dolor, instrumentos con otro tipo de atributo de interés, los $delta_i$ no tiene sentido que sean interpretados como "dificultades" (i.e, no expresan que un item sea más fácil o más díficil). Por ejemplo, en un modelo de victimización escolar (i.e., #strong[bullying items];), los estimados $delta_i$ los podriamos interpretar como la prorporción relativa con la que los eventos de acoso escolar ocurren. En un instrumento de #strong[vocabulario receptivo];, ítems con deltas de mayor valor permiten identificar a palabras menos reconocidas (i.e., palabras menos frecuentes entre los participantes).

=== De logits a proporción de respuesta
<de-logits-a-proporción-de-respuesta>
- Los resultados de dificultad de cada item, nos pueden servir para obtener la proporción de respuestas correctas esperadas a un nivel de habilidad.

- Empleando a la notación de este documento la ecuación que nos sirve para obtener las respuestas correctas esperadas es:

$ P r (y_p = 1 \| delta_i \, theta_p) = frac(e x p (theta_p - delta_i), 1 + e x p (theta_p - delta_i)) $

- Como la media de $theta_p$ es cero para el total de los participantes, podemos remover a $theta_p$ de la ecuación anterior, y obtener con esta la proporción de respuestas correctas esperadas por el modelo, para la habilidad media.

- Por ejemplo el item `y01` obtiene un logit de 0.15; si este lo sometemos a la formula para convertir logits a proporciones, obtendriamos que el ítem `y01` tiene una proporción de respuestas esperadas por el modelo de 54%.

- Como fue indicado anteriormente, la media del modelo para $theta_p$ es cero. Luego, podemos estimar directamente las proporciones de respuestas correctas por ítem usando los logits obtenidos .

- Podemos proceder de forma similar, para las respuestas incorrectas, con la siguiente ecuación:

$ P r (y_p = 0 \| delta_i \, theta_p) = frac(1, 1 + e x p (theta_p - delta_i)) $

- Ahora bien, si prestamos atención a la cantidad de respuestas correctas #emph[observadas];, veremos que para el ítem `y01` es de 53%. Note que existe una #emph[discrepancia] entre el observado y el modelo. Esto se produce por al menos dos aspectos: omisiones de respuestas, y error de medición. El modelo nos entrega la proporcion de respuesta esperadas, aunque no observaramos respuestas a cada ítem para todas las personas. Por otro lado, mientras mayor sea la varianza no explicada por el modelo (i.e., mayor error), menor es el ajuste entre respuestas esperadas, y respuestas observadas.

```r
table_obs <- data_model %>%
dplyr::select(y01:y16) %>%
summarize(
y01 = mean(y01 == 1, na.rm = TRUE),
y02 = mean(y02 == 1, na.rm = TRUE),
y03 = mean(y03 == 1, na.rm = TRUE),
y04 = mean(y04 == 1, na.rm = TRUE),
y05 = mean(y05 == 1, na.rm = TRUE),
y06 = mean(y06 == 1, na.rm = TRUE),
y07 = mean(y07 == 1, na.rm = TRUE),
y08 = mean(y08 == 1, na.rm = TRUE),
y09 = mean(y09 == 1, na.rm = TRUE),
y10 = mean(y10 == 1, na.rm = TRUE),
y11 = mean(y11 == 1, na.rm = TRUE),
y12 = mean(y12 == 1, na.rm = TRUE),
y13 = mean(y13 == 1, na.rm = TRUE),
y14 = mean(y14 == 1, na.rm = TRUE),
y15 = mean(y15 == 1, na.rm = TRUE),
y16 = mean(y16 == 1, na.rm = TRUE)
) %>%
tidyr::pivot_longer(
cols = y01:y16,
names_to = 'items',
values_to = 'observed'
)

table_exp <- rasch_tam %>%
purrr::pluck('xsi') %>%
dplyr::select(xsi) %>%
rename(tam_delta = xsi) %>%
mutate(expected =  exp(-tam_delta)/(1 + exp(-tam_delta))) %>%
dplyr::select(expected)

dplyr::bind_cols(table_obs,table_exp) %>%
mutate(dif = abs(observed) - abs(expected)) %>%
knitr::kable(., digits = 2)
```

#table(
  columns: 4,
  align: (left,right,right,right,),
  table.header([items], [observed], [expected], [dif],),
  table.hline(),
  [y01], [0.47], [0.46], [0.01],
  [y02], [0.76], [0.81], [-0.04],
  [y03], [0.85], [0.89], [-0.04],
  [y04], [0.87], [0.91], [-0.04],
  [y05], [0.55], [0.56], [-0.01],
  [y06], [0.35], [0.32], [0.03],
  [y07], [0.33], [0.30], [0.03],
  [y08], [0.73], [0.77], [-0.04],
  [y09], [0.57], [0.58], [-0.02],
  [y10], [0.45], [0.44], [0.01],
  [y11], [0.50], [0.50], [0.00],
  [y12], [0.36], [0.33], [0.03],
  [y13], [0.57], [0.59], [-0.02],
  [y14], [0.64], [0.67], [-0.03],
  [y15], [0.79], [0.84], [-0.04],
  [y16], [0.72], [0.76], [-0.04],
)
=== Ajuste de las respuestas al modelo
<ajuste-de-las-respuestas-al-modelo>
- Con los resultados ajustados, podemos juzgar si las respuestas frente a los ítems empleados ajustan poco al modelo. Para obtener indicadores de ajuste de los ítems al modelo podemos emplear la función `TAM::tam.fit()`

#block[
```r
# ---------------------------------------- 
# item fit
# ---------------------------------------- 

tam_00_fit <- TAM::tam.fit(rasch_tam)
```

#block[
```
Item fit calculation based on 5 simulations
|**********|
|----------|
```

]
]
- En la siguiente gráfica, empleamos a los #emph[infit] para evaluar si los ítems se encuentran por sobre valores .75 y 1.33 (Wilson, 2023). Estas son recomendaciones generales de tamaño de efecto de discrepancia, pero no son reglas infranqueables.

```r
# ---------------------------------------- 
# dotplot
# ---------------------------------------- 

infit_data <- dplyr::select(tam_00_fit$itemfit, parameter, Infit)

dotchart(infit_data$Infit, labels = infit_data$parameter,
         cex = 0.6, xlab = "Infit", xlim = c(0,2), 
         main = 'weighted mean square, items residuals')
abline(v=c(.75, 1.33), lty = 3)
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-23-1.svg"))]
- Item que se encuentran muy distantes de estos limites pueden ser considerados ítems que discrepan al modelo ajustado, por sobre lo esperado por la curva de información del modelo (i.e.~por sobre el inverso de la incertidumbre del modelo).

- Este tipo de indicadores debe interpretarse con cuatela, ya que estan basados en $chi^2$, y por tanto las pruebas los valores $p$ asociados a estos valores son sensibles al tamaño de la cantidad de observacions empleadas en los análisis. En escenarios de muestras grandes como en el caso de los estudios de gran escala, es muy posible que todos los valores $t$ sean signficativos (i.e.~valores $p$ \< .05; $p$ \< .01; $p$ \< .001).

```r
# ---------------------------------------- 
# item fit  tables with misfit responses
# ---------------------------------------- 

# responses with lnfit > 1.33 or Infit <.75 and Infit_t > 2

library(dplyr)
item_fit_infit <- tam_00_fit$itemfit %>%
                  dplyr::filter(
                    abs(Infit_t) >2 & Infit > 1.33 | 
                    abs(Infit_t) >2 & Infit <  .75)

knitr::kable(tam_00_fit$itemfit, digits=2)
```

#table(
  columns: (12.2%, 8.54%, 10.98%, 10.98%, 15.85%, 7.32%, 9.76%, 9.76%, 14.63%),
  align: (left,right,right,right,right,right,right,right,right,),
  table.header([parameter], [Outfit], [Outfit\_t], [Outfit\_p], [Outfit\_pholm], [Infit], [Infit\_t], [Infit\_p], [Infit\_pholm],),
  table.hline(),
  [y01], [1.04], [3.69], [0.00], [0.00], [1.03], [2.42], [0.02], [0.14],
  [y02], [0.94], [-3.04], [0.00], [0.01], [0.98], [-0.87], [0.39], [1.00],
  [y03], [0.81], [-7.83], [0.00], [0.00], [0.94], [-2.18], [0.03], [0.23],
  [y04], [0.78], [-8.36], [0.00], [0.00], [0.92], [-2.77], [0.01], [0.07],
  [y05], [1.17], [13.62], [0.00], [0.00], [1.12], [9.89], [0.00], [0.00],
  [y06], [1.01], [1.04], [0.30], [0.89], [0.99], [-0.65], [0.52], [1.00],
  [y07], [1.09], [6.05], [0.00], [0.00], [1.04], [2.50], [0.01], [0.12],
  [y08], [0.95], [-3.35], [0.00], [0.00], [0.98], [-1.46], [0.14], [1.00],
  [y09], [1.05], [4.26], [0.00], [0.00], [1.03], [2.62], [0.01], [0.10],
  [y10], [0.95], [-4.44], [0.00], [0.00], [0.94], [-4.60], [0.00], [0.00],
  [y11], [1.04], [3.12], [0.00], [0.01], [1.01], [1.20], [0.23], [1.00],
  [y12], [1.13], [9.33], [0.00], [0.00], [1.08], [5.63], [0.00], [0.00],
  [y13], [1.00], [-0.37], [0.71], [1.00], [1.00], [0.34], [0.73], [1.00],
  [y14], [0.99], [-0.50], [0.62], [1.00], [1.00], [-0.02], [0.98], [1.00],
  [y15], [0.80], [-10.60], [0.00], [0.00], [0.91], [-4.58], [0.00], [0.00],
  [y16], [0.94], [-3.80], [0.00], [0.00], [0.99], [-0.91], [0.36], [1.00],
)
- Para el caso del test analizado, todos los ítems de la prueba en esta aplicación parecen comportarse de forma adecuada.

=== Distribución de dificultades
<distribución-de-dificultades>
- Si ordenamos a los ítems en términos de su dificultad, podemos tener una noción de cuales son los items más representativos de alto conocimiento cívico, cuáles de conocimiento medio, y cuáles de menor conocimiento.

```r
item_table <- read.table(text = "
var     item_text
u01     '[u][k = 4] ORGANIZED CRIME                        '
u02     '[u][k = 1] DEALING WITH OPPOSITION GROUPS         '
u03     '[u][k = 3] TRAFFIC LAWS                           '
u04     '[u][k = 4] ALCOHOL AND TOBACCO SALES TO MINORS    '
u05     '[u][k = 1] VIOLENCE IN CONGRESS                   '
u06     '[u][k = 4] CONSEQUENCES OF LA DICTORSHIPS         '
u07     '[u][k = 3] CONSITITUTION DEFINITION               '
u08     '[u][k = 3] EQUAL EMPLOYMENT OPPORTUNITY           '
u09     '[u][k = 2] CONSEQUENCE OF LA VOTER APATHY         '
u10     '[u][k = 1] CHARACTERISTIC OF LA DICTATORSHIPS     '
u11     '[u][k = 1] RISK SITUATIONS FOR DEMOCRACY          '
u12     '[u][k = 4] DEMOCRATIC LEADERSHIP                  '
u13     '[u][k = 2] AUTHORITARAIN GOV CHARCTERISTIC        '
u14     '[u][k = 1] STATE RESPONSIBILITY FOR JUSTICE SYSTEM'
u15     '[u][k = 4] INDIGENOUS RIGHTS TO PRESERVE CULTURE  '
u16     '[u][k = 2] VOTING AS DEMOCRATIC PROCESS           '
", header = TRUE)

coef(rasch_rep) %>%
purrr::pluck('id_p') %>%
dplyr::select(u01:u16) %>%
unique() %>%
tidyr::pivot_longer(
cols = u01:u16,
names_to = 'var',
values_to = 'delta'
) %>%
dplyr::left_join(.,
item_table, by = 'var') %>%
arrange(delta) %>%
knitr::kable(., digits = 2)
```

#table(
  columns: 3,
  align: (left,right,left,),
  table.header([var], [delta], [item\_text],),
  table.hline(),
  [u04], [-2.28], [\[u\]\[k = 4\] ALCOHOL AND TOBACCO SALES TO MINORS],
  [u03], [-2.11], [\[u\]\[k = 3\] TRAFFIC LAWS],
  [u15], [-1.62], [\[u\]\[k = 4\] INDIGENOUS RIGHTS TO PRESERVE CULTURE],
  [u02], [-1.42], [\[u\]\[k = 1\] DEALING WITH OPPOSITION GROUPS],
  [u08], [-1.21], [\[u\]\[k = 3\] EQUAL EMPLOYMENT OPPORTUNITY],
  [u16], [-1.15], [\[u\]\[k = 2\] VOTING AS DEMOCRATIC PROCESS],
  [u14], [-0.71], [\[u\]\[k = 1\] STATE RESPONSIBILITY FOR JUSTICE SYSTEM],
  [u13], [-0.37], [\[u\]\[k = 2\] AUTHORITARAIN GOV CHARCTERISTIC],
  [u09], [-0.34], [\[u\]\[k = 2\] CONSEQUENCE OF LA VOTER APATHY],
  [u05], [-0.23], [\[u\]\[k = 1\] VIOLENCE IN CONGRESS],
  [u11], [0.00], [\[u\]\[k = 1\] RISK SITUATIONS FOR DEMOCRACY],
  [u01], [0.15], [\[u\]\[k = 4\] ORGANIZED CRIME],
  [u10], [0.24], [\[u\]\[k = 1\] CHARACTERISTIC OF LA DICTATORSHIPS],
  [u12], [0.69], [\[u\]\[k = 4\] DEMOCRATIC LEADERSHIP],
  [u06], [0.74], [\[u\]\[k = 4\] CONSEQUENCES OF LA DICTORSHIPS],
  [u07], [0.87], [\[u\]\[k = 3\] CONSITITUTION DEFINITION],
)
- Podemos ilustrar lo anterior de forma gráfica con un histograma de las deltas obtenidos con el modelo ajustado, donde los delta fueron parametrizados como "dificultades".

```r
hist(x = table_2$param_2,
ylab = 'frecuencia',
xlab = 'deltas',
main = 'Histograma de dificultades de items'
)
abline(v = 0, col = "red", lty = 1)
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-26-1.svg"))]
- Contamos con cerca de 6 items sobre cero, y 10 items bajo cero en la escala de logits. Los modelos ajustados estan paramétrizados de forma tal que el cero de $theta_p$, refiere a la media del efecto aleatorio ( $theta_p$ ). En consecuencia, contamos con más items bajo la media de $theta_p$, que sobre la media de $theta_p$.

- Con esta parametrización podríamos sospechar que, dados los resultados observados esta prueba resulta ser más #strong[informativa] para el bajo conocimiento cívico que para el alto nivel de conocimiento cívico.

- Cuando una prueba carece de ítems en un sector de la distribución de $theta_p$, entonces dificilmente la prueba o instrumento empleado puede caracterizar a este sector de la distribución de la propensión de interés.

- En términos ideales, una prueba altamente informativa de un atributo de interés de una población de participantes, debiera presentar una suerte de #emph[match] entre la habilidad de evaluada y las locaciones de los items. Esta última idea, la ilustramos con el siguiente diagrama (ver Carrasco et al., 2023).

```r
knitr::include_graphics('./03_img/match_delta_theta.jpg')
```

#align(center)[#box(image("./03_img/match_delta_theta.jpg", width: 80.0%))]
- Nótese, que la idea de precisión de puntajes con IRT es una propiedad específica de cada media generada. Es decir, que se puede tener un puntaje total de una prueba que tenga alta confiabilidad y aun así contar con sectores de puntajes en la prueba, donde los errores asociados a las realizaciones puedan ser poco precisos a un propósito particular. Por ejemplo, que en un proceso de certificación o clasificación de logrado y no logrado, el punto de corte empleado tenga poca precisión.

== Interpretación de los theta (#emph[person side];)
<interpretación-de-los-theta-person-side>
- Los términos $theta_p$ son las posiciones de los personas en el continuo que produce el modelo. Estos son los términos que, en los estudios de gran escala, son luego convertidos a escalas de media de 500 puntos, y desviación estandar de 100 puntos, y con los que se producen los valores plausibles.

- Los valores de estos términos no significan nada en sí mismos; sino que poseen un significado e interpretación posibles de acuerdo al modelo especificado, siempre en terminos relativos, y referidos a los contenidos de los ítems empleados. En la especificación que estamos empleando, donde la media de $theta_p$ es cero, empleamos este punto de referencia para la interpretación de resultados.

- Formalmente, $theta_p$ es un variable latente, de distribución normal, y varianza libre.

$ theta_p tilde.op upright("Normal") (mu \, sigma^2) $

- Los $theta_p$ tienen sentido de acuerdo al contenido de los items del instrumento. En este caso, sabemos que $P r (y_i = 1)$, como conjunto, implican mayor y menor conocimiento cívico.

- Una de las propiedades de los modelos Rasch, es que las posiciones relativas de los ítems y de las personas, se encuentran en una misma escala. Y como tal, podemos hacer comparaciones de dónde están las personas con respecto a cómo contesta la totalidad de las observaciones.

- Vamos a generar un diagrama de ítems personas (i.e., #emph[item-person maps];, #emph[WrightMaps];), con el cual será más facil ilustrar la interpretación de resultados. Vamos a emplear a la libreria `library(TAM)`, de modo que podamos ajustar un modelo Rasch de forma tradicional.

=== Item-person map
<item-person-map>
- Los diagramas de items-personas incluyen a un histograma de las realizaciones del término $theta_p$. Se les llama realizaciones, o predicciones porque son un término generado con el modelo, que no pre-existen a la base de datos. Son #emph[representaciones];, en algún sentido, de la variable latente que supone el modelo.

```r
# -----------------------------------------------
# items
# -----------------------------------------------

item_text <- read.table(text = "
item    item_text
y01     '[u01][k = 4] ORGANIZED CRIME                        '
y02     '[u02][k = 1] DEALING WITH OPPOSITION GROUPS         '
y03     '[u03][k = 3] TRAFFIC LAWS                           '
y04     '[u04][k = 4] ALCOHOL AND TOBACCO SALES TO MINORS    '
y05     '[u05][k = 1] VIOLENCE IN CONGRESS                   '
y06     '[u06][k = 4] CONSEQUENCES OF LA DICTORSHIPS         '
y07     '[u07][k = 3] CONSITITUTION DEFINITION               '
y08     '[u08][k = 3] EQUAL EMPLOYMENT OPPORTUNITY           '
y09     '[u09][k = 2] CONSEQUENCE OF LA VOTER APATHY         '
y10     '[u10][k = 1] CHARACTERISTIC OF LA DICTATORSHIPS     '
y11     '[u11][k = 1] RISK SITUATIONS FOR DEMOCRACY          '
y12     '[u12][k = 4] DEMOCRATIC LEADERSHIP                  '
y13     '[u13][k = 2] AUTHORITARAIN GOV CHARCTERISTIC        '
y14     '[u14][k = 1] STATE RESPONSIBILITY FOR JUSTICE SYSTEM'
y15     '[u15][k = 4] INDIGENOUS RIGHTS TO PRESERVE CULTURE  '
y16     '[u16][k = 2] VOTING AS DEMOCRATIC PROCESS           '
", header = TRUE)

# -----------------------------------------------
# response data
# -----------------------------------------------

data_resp <- data_model %>%
             dplyr::select(y01:y16)

# -----------------------------------------------
# unique identifier
# -----------------------------------------------

id_p_list <- data_model %>%
             dplyr::select(id_p) %>%
             dplyr::pull()

# -----------------------------------------------
# fit model
# -----------------------------------------------

rasch_tam <- TAM::tam(
             resp = data_resp, 
             pid = id_p_list,
             irtmodel = "1PL", 
             verbose = FALSE
             )

# -----------------------------------------------
# theta realizations
# -----------------------------------------------

theta_data  <- TAM::tam.wle(rasch_tam, progress = FALSE) %>%
               rename(id_i = pid) %>%
               rename(theta = theta) %>%
               rename(theta_se = error) %>%
               dplyr::select(id_i, theta, theta_se) %>%
               dplyr::glimpse()
## Rows: 5,173
## Columns: 3
## $ id_i     <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18…
## $ theta    <dbl> 0.70745545, -0.52017176, 0.06119417, -2.18746464, 0.37215291,…
## $ theta_se <dbl> 0.6106923, 0.5915351, 0.5631878, 0.6705852, 0.5809106, 0.6106…

# -----------------------------------------------
# delta estimates
# -----------------------------------------------

delta_data <- rasch_tam %>%
              purrr::pluck('xsi') %>%
              mutate(item = row.names(.)) %>%
              mutate(logit = xsi) %>%
              mutate(logit_se = se.xsi) %>%
              dplyr::select(item, logit, logit_se) %>%
              dplyr::left_join(., item_text, by = 'item') %>%
              mutate(order_plot = '1') %>%
              # arrange(logit) %>%
              mutate(x_pos = seq(1:nrow(.))) %>%
              mutate(item_fct = factor(item)) %>%
              dplyr::glimpse()
## Rows: 16
## Columns: 7
## $ item       <chr> "y01", "y02", "y03", "y04", "y05", "y06", "y07", "y08", "y0…
## $ logit      <dbl> 0.150213919, -1.421742759, -2.113204407, -2.281350412, -0.2…
## $ logit_se   <dbl> 0.03119883, 0.03577134, 0.04200841, 0.04412297, 0.03114580,…
## $ item_text  <chr> "[u01][k = 4] ORGANIZED CRIME                        ", "[u…
## $ order_plot <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1",…
## $ x_pos      <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
## $ item_fct   <fct> y01, y02, y03, y04, y05, y06, y07, y08, y09, y10, y11, y12,…

# -----------------------------------------------
# display
# -----------------------------------------------

knitr::kable(delta_data, digits = 2)
```

#table(
  columns: (5.05%, 6.06%, 9.09%, 53.54%, 11.11%, 6.06%, 9.09%),
  align: (left,right,right,left,left,right,left,),
  table.header([item], [logit], [logit\_se], [item\_text], [order\_plot], [x\_pos], [item\_fct],),
  table.hline(),
  [y01], [0.15], [0.03], [\[u01\]\[k = 4\] ORGANIZED CRIME], [1], [1], [y01],
  [y02], [-1.42], [0.04], [\[u02\]\[k = 1\] DEALING WITH OPPOSITION GROUPS], [1], [2], [y02],
  [y03], [-2.11], [0.04], [\[u03\]\[k = 3\] TRAFFIC LAWS], [1], [3], [y03],
  [y04], [-2.28], [0.04], [\[u04\]\[k = 4\] ALCOHOL AND TOBACCO SALES TO MINORS], [1], [4], [y04],
  [y05], [-0.23], [0.03], [\[u05\]\[k = 1\] VIOLENCE IN CONGRESS], [1], [5], [y05],
  [y06], [0.74], [0.03], [\[u06\]\[k = 4\] CONSEQUENCES OF LA DICTORSHIPS], [1], [6], [y06],
  [y07], [0.87], [0.03], [\[u07\]\[k = 3\] CONSITITUTION DEFINITION], [1], [7], [y07],
  [y08], [-1.21], [0.03], [\[u08\]\[k = 3\] EQUAL EMPLOYMENT OPPORTUNITY], [1], [8], [y08],
  [y09], [-0.34], [0.03], [\[u09\]\[k = 2\] CONSEQUENCE OF LA VOTER APATHY], [1], [9], [y09],
  [y10], [0.24], [0.03], [\[u10\]\[k = 1\] CHARACTERISTIC OF LA DICTATORSHIPS], [1], [10], [y10],
  [y11], [0.00], [0.03], [\[u11\]\[k = 1\] RISK SITUATIONS FOR DEMOCRACY], [1], [11], [y11],
  [y12], [0.69], [0.03], [\[u12\]\[k = 4\] DEMOCRATIC LEADERSHIP], [1], [12], [y12],
  [y13], [-0.37], [0.03], [\[u13\]\[k = 2\] AUTHORITARAIN GOV CHARCTERISTIC], [1], [13], [y13],
  [y14], [-0.71], [0.03], [\[u14\]\[k = 1\] STATE RESPONSIBILITY FOR JUSTICE SYSTEM], [1], [14], [y14],
  [y15], [-1.62], [0.04], [\[u15\]\[k = 4\] INDIGENOUS RIGHTS TO PRESERVE CULTURE], [1], [15], [y15],
  [y16], [-1.15], [0.03], [\[u16\]\[k = 2\] VOTING AS DEMOCRATIC PROCESS], [1], [16], [y16],
)
```r

# -----------------------------------------------
# limits
# -----------------------------------------------

low_limit <- -5
upp_limit <-  5

max_cat   <- 1

# -----------------------------------------------
# histogram
# -----------------------------------------------

library(ggpubr)
library(ggplot2)
p1 <- gghistogram(theta_data,
      x = "theta",
      fill = "grey90",
      binwidth = .35,
      ggtheme = theme_bw()
      ) +
      remove('x.grid') +
      xlab('') + ylab(expression(theta[p])) +
    scale_x_continuous(
      limits = c(low_limit, upp_limit),
      breaks = seq(low_limit, upp_limit, 1))

# -----------------------------------------------
# scale name
# -----------------------------------------------

scale_name <- 'ICCS 2019 (lat)'

# -----------------------------------------------
# delta plot data
# -----------------------------------------------

delta_plot <- delta_data

# -----------------------------------------------
# item text for plots (1)
# -----------------------------------------------

item_text_plot <- delta_plot %>%
                  arrange(logit) %>%
                  dplyr::select(item_text) %>%
                  dplyr::pull()
# -----------------------------------------------
# item text for plots (2)
# -----------------------------------------------

item_label_text <- c(
'[u04][k = 4] ALCOHOL AND TOBACCO SALES TO MINORS    ',
'[u03][k = 3] TRAFFIC LAWS                           ',
'[u15][k = 4] INDIGENOUS RIGHTS TO PRESERVE CULTURE  ',
'[u02][k = 1] DEALING WITH OPPOSITION GROUPS         ',
'[u08][k = 3] EQUAL EMPLOYMENT OPPORTUNITY           ',
'[u16][k = 2] VOTING AS DEMOCRATIC PROCESS           ',
'[u14][k = 1] STATE RESPONSIBILITY FOR JUSTICE SYSTEM',
'[u13][k = 2] AUTHORITARAIN GOV CHARCTERISTIC        ',
'[u09][k = 2] CONSEQUENCE OF LA VOTER APATHY         ',
'[u05][k = 1] VIOLENCE IN CONGRESS                   ',
'[u11][k = 1] RISK SITUATIONS FOR DEMOCRACY          ',
'[u01][k = 4] ORGANIZED CRIME                        ',
'[u10][k = 1] CHARACTERISTIC OF LA DICTATORSHIPS     ',
'[u12][k = 4] DEMOCRATIC LEADERSHIP                  ',
'[u06][k = 4] CONSEQUENCES OF LA DICTORSHIPS         ',
'[u07][k = 3] CONSITITUTION DEFINITION               '
  )

# -----------------------------------------------
# dotplot
# -----------------------------------------------

library(ggpubr)
library(ggplot2)
p2 <- delta_plot %>%
      ggdotchart(., 
      x = "item", 
      y = "logit",
      group = "order_plot", 
      color = "order_plot",
      palette = c('grey50','black', 'grey70'),
      rotate = TRUE,
      # sorting = 'asc',
      ggtheme = theme_bw(),
      y.text.col = FALSE ) +
      rremove('x.grid') +
      rremove('legend') +
      xlab(bquote(tau['1k'] ~ "-" ~ tau[.(max_cat)])) +
      ylab(scale_name) +
      geom_text(
       aes(
         label = item_label_text,
         y = low_limit,
         x = x_pos - .25),
         colour = "grey50",
         size = 3,
         hjust = 0,
         inherit.aes = FALSE
         ) +
       scale_y_continuous(
         limits = c(low_limit, upp_limit),
         breaks = seq(low_limit, upp_limit, 1))

# -----------------------------------------------
# join plots
# -----------------------------------------------

item_map <- ggarrange(p1, p2,
            ncol = 1,
            nrow = 2,
            heights = c(1,2.5),
            align = 'v')

# -----------------------------------------------
# item person map
# -----------------------------------------------

item_map
```

#block[
#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-28-1.svg"))]
]
```r
knitr::include_graphics('./03_img/item_person_map_iccs_2009_lat.jpg')
```

#align(center)[#box(image("./03_img/item_person_map_iccs_2009_lat.jpg", width: 80.0%))]
- Mayor valor en $theta_p$, implica que las personas son más proclives a entregar respuestas correctas sobre los ítems.

- En términos muy generales, serían propensiones de las personas a contestar de una forma. En este caso, de seleccionar alternativas correctas segun la rúbrica de corrección aplicada.

- Podemos interpretar el ítem más difícil, con respecto a las personas. En el ejemplo usado aquí, este corresponde al ítem `y07`, el cual corresponde a la variable original `LS2T07`. En esta pregunta los estudiantes deben identificar cual es el texto jurídico de un sistema democrático, el cual establece derechos y deberes, y regula al funcionamiento del estado (la constitución).

- En el diagrama de items-personas, podemos ver que la locación del ítem en los resultados del modelo es cerca de 1 logit. Si tomo un grupo de personas que tuvieran como promedio 1 logit, dado los resultados del modelo puedo tener la expectativa de que 50% de las personas de este grupo conteste de forma correcta a este item; y en consecuencia, que 50% restante de este grupo ideal, no conteste de forma correcta a este item.

- Con este diagrama, podemos interpretar los puntajes realizados de $theta_p$ en términos de las personas acerca de qué ítems resuelven.

- Por ejemplo, si nos fijamos en los estudiantes de bajo puntaje (menor a -2 logits), del lado izquiero de la distribución de puntajes, podemos indicar que entienden porque el alcohol y el tabaco no debieran ser vendidos a menores de edad (`y04`), y entienden el rol de las leyes del transito (`y03`). Sin embargo, estos estudiantes no serían capaces de indicar las consecuencias de las dictaduras en latinoamérica (`y06`, 0.73 logit).

- Los estudiantes en el promedio de Chile, por su parte, tienen un 50% de chances de identificar situaciones que son riesgosas para un sistema democrático (`y11`, -0.01). Tal como que en portada de los periódicos apareciera que hay amenazas contra partidarios de la oposición, durante campaña electoral.

- Finalmente, los estudiantes de mayor desempeño en la prueba aplicada, pueden indicar una de las las consecuencias de las dictaduras en latinoamérica (#emph[Muchos de los opositores tuvieron que salir de los países en dictadura.];, `LS2T06`, 1 logit).

=== Puntaje total y puntajes IRT
<puntaje-total-y-puntajes-irt>
- Una forma de representar de forma sencilla a $theta_p$ son las sumas de respuestas correctas, o sumas de puntajes. En escenarios de datos completos (i.e., sin datos perdidos), estos presentan una correlación de casi 1:1 a con las realizaciones de $theta_p$.

- En la siguiente gráfica, nos quedamos solo con las personas que contestan a los 16 items de forma correcta o incorrecta, y extraemos las realizaciones EAP del modelo.

```r
library(ggplot2)
rasch_tam$person %>%
dplyr::filter(max == 16) %>%
na.omit() %>%
ggplot(., aes(EAP, score)) + 
geom_point(shape = 20, aes(alpha = .5), size = 3, colour = "grey20", show.legend = FALSE) + 
geom_line(aes(alpha = .5), size = 3, colour = "grey20", show.legend = FALSE) + 
theme_minimal() + 
theme(
panel.background = element_rect(fill = NA, linetype = "dashed", colour = "grey20", size = 0.12), 
panel.grid.major = element_line(size = 0.12, linetype = "dashed", colour = "grey20"),
panel.grid.minor = element_blank(), 
panel.border = element_rect(linetype = "solid", fill = NA)) + 
scale_x_continuous(
  name = expression(theta), 
  limits =   c(-3, 3), 
  breaks = seq(-3, 3, 1)
  ) + 
scale_y_continuous(
  name = expression("Puntaje Total (Suma de respuestas)"), 
  limits = c(0, 16), 
  breaks = seq(0, 16, 1)
  )
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-30-1.svg"))]
- Esta idea, de que el puntaje sumado o promedio de respuestas tenga una correlación 1:1 con las realizaciones de $theta_p$, se conoce como #strong[monotonicidad] (Kang et al., 2018). En diferentes aplicaciones del modelo Rasch, se emplea esta propiedad para representar a $theta_p$ mediante el puntaje total, gracias a que esto posee ciertas ventajas y conveniencias (e.g., Skrondal, 2022). En términos conceptuales, #emph[conditional maximum likelihood] emplea esta propiedad, que en la literatura de IRT aparece mencionado como que el puntaje total, es un #emph[estadístico suficiente] (Masters, 1982). Literalmente, consiste en el ejericio de obtener las dificultades de los items, realizando una regresión logistica, donde se ingresa al puntaje total como variable control.

- Gracias a esta propiedad del modelo entonces podemos decir que mayor valor de $theta_p$, mayor es la cantidad de respuestas correctas.

== Confiabilidad condicional
<confiabilidad-condicional>
- Los modelos IRT, como son modelos mixtos, permiten generar o producir "interceptos aleatorios", con grados de incertidumbre específica. Cada $theta_p$ posee un error estándar específico. Gracias a este error específico, que acompaña a cada $theta_p$, se puede tener una medida de confiabilidad (i.e., precisión) de cada media generada.

- En consecuencia, un modelo IRT puede tener sectores con mayor precisión, y sectores con medias latentes de menor precisión.

- En el caso de la prueba analizada hay menos precisión en los puntajes altos que en los puntajes bajos. Esto se produce porque hay pocos ítems en el lado derecho de la distribución.

- El siguiente gráfico es una #emph[caterpillar plot] (Rabe-Hesket et al, 2012; Goldstein et al., 1995), donde junto a las medias latentes generadas con el modelo ( $theta_p$ ) se incluyen los intervalos de confianza de las medias empleando a los errores estándar de cada media latente. Como estas son realizaciones bayesianas, estos intervalos son intervalos credibles.

- En particular, en esta gráfica ordenamos a las medias latente generadas, empleando a los EAP, y sus desviaciones estándar, y las multiplicamos por 1.96 a cada lado. Generamos una muestra de solo 200 medias latentes, y graficamos como un punto a cada media, y como líneas a las medidas de dispersión que tenemos de cada media generada.

```r
knitr::include_graphics('./03_img/caterpillar_plot_theta.jpg')
```

#align(center)[#box(image("./03_img/caterpillar_plot_theta.jpg", width: 80.0%))]
- En escenarios en que el tamaño de la incertidumbre alrededor de los puntajes en una de las colas, o en sectores con menos indicadores, la extensión de los errores sería mucho más exagerada (más grande). Por ejemplo, en escala en que los items poseen locaciones menores, y observaramos a una gran cantidad de casos con puntaje alto o máximo, las medias del lado derecho de la distribución tendrian errores más grandes que la cola inferior.

- Otra forma de ilustrar la idea anterior es con un dispersiograma, con el cual revisemos a los errores esperados de las realizaciones de $theta_p$, y sus errores estándar. Vamos a emplear las realizaciones EAP de $theta_p$ para construir el siguiente gráfico, y las desviaciones estándar que acompañan a estas realizaciones (ver Brown et al, 2015 para una variante empleando a la curva de información).

```r
# get EAP estimates from tam results
data_eta <- data.frame(
theta    = rasch_tam$person$EAP,
theta_se = rasch_tam$person$SD.EAP
)

# draw plot
library(ggplot2)
scatter_plot <- ggplot(data_eta, aes(theta, theta_se)) + 
        geom_point(shape = 20, 
        aes(alpha = .5), size = 3, colour = "grey20", show.legend = FALSE) + 
        theme_minimal() + theme(panel.background = element_rect(fill = NA, 
        linetype = "dashed", colour = "grey20", size = 0.25), 
        panel.grid.major = element_line(size = 0.25, linetype = "dashed", 
            colour = "grey20"), panel.grid.minor = element_blank(), 
        panel.border = element_rect(linetype = "solid", fill = NA)) + 
        scale_x_continuous(name = expression(theta), limits = c(-4, 
            4), breaks = seq(-4, 4, 1)) + scale_y_continuous(name = expression(SE(theta)), 
        limits = c(0, 1.5), breaks = seq(0, 1.5, 0.25))

# display plot
ggExtra::ggMarginal(scatter_plot, 
  type = "histogram", 
  colour = "grey20", 
  alpha = 0.15, 
  fill = "grey90"
)
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-33-1.svg"))]
#block[
#callout(
body: 
[
Las realizaciones de $theta_p$ de tipo EAP son #emph[expected a posteriori] del modelo. Son realizaciones #emph[bayesianas] de la variable latente $theta_p$, y por tanto pueden tener una media, y una desviación estándar. Mientras más grande sean las desviaciones estándar de las realizaciones, mayor incertidumbre tenemos con la media en cuestión. Los EAP, son una forma de obtener predicciones, o realizaciones de $theta_p$. Existen otras formas de obtener predicciones, como los WLE o #emph[weighted least estimate];. Tradicionalmente, en los estudios de gran escala de la IEA, en que se emplea modelos rasch sobre escalas de cuestionarios de contexto, los puntajes son creados con transformaciones lineales de los WLE generados.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
- El efecto de que los errores sean mayores donde hay menos ítems tambien puede ser obtenido con los WLE.

```r
# get wle estimates
tam_wle  <- TAM::tam.wle(rasch_tam, progress = FALSE)

# get theta and disperions
theta_wle  <- tam_wle$theta
theta_se   <- tam_wle$error

# data for plot
data_theta_wle <- data.frame(
theta    = theta_wle,
theta_se = theta_se
)

# create plot
library(ggplot2)
scatter_plot <- ggplot(data_theta_wle, aes(theta, theta_se)) + 
        geom_point(shape = 20, 
        aes(alpha = .5), size = 3, colour = "grey20", show.legend = FALSE) + 
        theme_minimal() + theme(panel.background = element_rect(fill = NA, 
        linetype = "dashed", colour = "grey20", size = 0.25), 
        panel.grid.major = element_line(size = 0.25, linetype = "dashed", 
            colour = "grey20"), panel.grid.minor = element_blank(), 
        panel.border = element_rect(linetype = "solid", fill = NA)) + 
        scale_x_continuous(name = expression(theta), limits = c(-4, 
            4), breaks = seq(-4, 4, 1)) + scale_y_continuous(name = expression(SE(theta)), 
        limits = c(0, 2), breaks = seq(0, 2, 0.25))

# display plot
ggExtra::ggMarginal(scatter_plot, 
  type = "histogram", 
  colour = "grey20", 
  alpha = 0.15, 
  fill = "grey90"
)
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-34-1.svg"))]
- Tradicionalmente, esta idea es ilustrada con la #strong[curva de información];. Esta curva encuentra su peak donde más ítems posea una prueba.

```r
plot(TAM::IRT.informationCurves(rasch_tam, theta = seq(-6,6,len=500)))
```

#align(center)[#box(image("03_rasch_files/figure-typst/unnamed-chunk-35-1.svg"))]
- En el caso de la prueba presente, para la muestra de estudiantes de Chile, el peak de información esta desplazado de la media de $theta_p$, siendo consistente con nuestra observación anterior: hay más items bajo la media que sobre la media.

== Valores Plausibles
<valores-plausibles>
=== Qué son los valores plausibles
<qué-son-los-valores-plausibles>
- Los valores plausibles son realizaciones aleatoras (#emph[random draws];) de $theta_p$ del modelo ajustado (Wu, 2005). Es decir que, dado un modelo, podemos generar infinitos valores que provienen del modelo definido.

```r
knitr::include_graphics('./03_img/pv_draw.jpg')
```

#align(center)[#box(image("./03_img/pv_draw.jpg", width: 80.0%))]
- Tradicionalmente los estudios de gran escala generan 5 valores plausibles. Excepcionalmente, un ciclo de PISA incluyo 10 valores plausibles. Estudios de simulaciones sugieren que se podrian requerir hasta 20 valores plausibles para representar con precisión a lo que se puede producir con los EAP (Luo et al, 2019). De esta manera, como todo ejercicio de imputación, la cantidad de realizaciones requeridas del modelo, para que estas puedan reproducir lo que se observa con el modelo que genera los resultados puede variar bajo diferentes condiciones.

- Este tipo de variables puede ser empleado para representar al error de medición de $theta_p$ en dos pasos (e.g., Pokoprek, 2015). Es decir, generando diferentes valores plausibles, y luego reanalizandolos en un segundo modelo como si estos fueran imputaciones.

=== Limitaciones de los valores plausibles
<limitaciones-de-los-valores-plausibles>
- Sin embargo, este tipo de generación de puntajes tiene limitaciones. Este tipo de puntajes puede tener problemas para reproducir los efectos no considerados por el modelo condicional que las produce. En la práctica, si el modelo condicional que produce los puntajes, y el segundo modelo analítico que se empleara sobre las imputaciones no fuera #strong[congenial] al modelo de origen, se corre el riesgo que el modelo analítico obtenga estimados distorsionados (Bran et al., 2017; Zheng, 2023). Esto puede ser una limitación importante para los estudios que hacen uso de los valores plausibles para estimar modelos multinivel, y para los estudios enfocados al estudio de interacciones entre covariables. Sin embargo, hay alternativas para tratar de enmendar estas limitaciones (ver Diakow, 2013, como ejemplo).

- Vamos a ilustrar esta limitación empleando un ejercicio. Vamos a ajustar un modelo de regresión latente sobre los ítems, condicionando a las respuestas con la covariable `pri`. Esta variable distingue a los estudiantes que asisten a escuelas privadas, en contraste a escuelas públicas y subvencionadas en Chile.

- De este modo, nuestro modelo de interés lo podemos expresar de la siguiente manera:

$ theta_p = beta_0 + beta_1 upright("Private") + epsilon.alt_p $

- De forma mas completa, nuestro modelo implica lo siguiente:

$ l n [P r (y_(i p) = 1)] = theta_p - delta_i + beta_1 upright("Private") $

- Lo que queremos ilustrar, es si podemos recuperar a $beta_1$ generado con el modelo de regresión latente, empleando a variantes de los valores plausibles.

- Vamos a generar dos versiones de 5 valores plausibles cada una. La primera, produce 5 valores plausibles, donde el predictor `pri` es parte del modelo. Es decir, que el modelo que genera los datos, contempla a la relación entre `pri` y $theta_p$ (PV condicionado). Y un segundo conjunto de valores plausibles que no incluye a `pri`, como parte de la cadena de covariables en el modelo generador de datos (PV nulo).

#block[
#callout(
body: 
[
La idea de #strong[modelo generador de datos] (i.e., #emph[data generating mechanism];, #emph[DGM];), es muy importante en la inferencia basada en modelos. El DGM, es la entidad sobre la cual se realizan inferencias, es el objetivo de la inferencia basada en modelos (Rabe-Hesket et al., 2012; Sterba, 2009). En los estudios de simulación, el rol del #strong[DGM] es explícito. Con este se generan datos, con los cuales se realizan conclusiones, de acuerdo a las condiciones que fueran variando en términos de las muestras de valores que se extraen del modelo que genera a los datos. En este sentido, los valores plausibles representan a un modelo que representa a las respuestas observadas; pero es distinto de las respuestas observadas.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
- Bajo la siguiente pestaña de código se encuentran todos los pasos llevados a cabo para producir los estimados comparados. Es decir que:

  - ajustamos un modelo de regresión latente como se describe anteriormente

  - generamos valores plausibles incluyendo al predictor de interés, con el modelo anterior

  - generamos valores plausibles con el modelo sin covariables

  - Luego, ajustamos modelos de regresión para los dos sets de valores plausibles

  - finalmente construimos una tabla comparada de los estimados obtenidos

#block[
```r
# -----------------------------------------------
# latent regression
# -----------------------------------------------

x_cov <- data_model[, 'pri']

rasch_cov <- TAM::tam(
             resp = data_resp, 
             pid = id_p_list,
             irtmodel = "1PL", 
             verbose = FALSE,
             Y = x_cov
             )

# -----------------------------------------------
# pv null
# -----------------------------------------------

tam_pv_nul <- TAM::tam.pv(rasch_tam, 
              nplausible=5, 
              ntheta=500, 
              normal.approx=TRUE
              )
## |*****|
## |-----|

# -----------------------------------------------
# pv conditioned
# -----------------------------------------------

tam_pv_pri <- TAM::tam.pv(rasch_cov, 
              nplausible=5, 
              ntheta=500, 
              normal.approx=TRUE,
              samp.regr=TRUE
              )
## |*****|
## |-----|

# -----------------------------------------------
# extract generated pv
# -----------------------------------------------

# null model or unconditioned
data_nul <- tam_pv_nul$pv %>%
rename(id_p = pid) %>%
rename(pv1 = PV1.Dim1) %>%
rename(pv2 = PV2.Dim1) %>%
rename(pv3 = PV3.Dim1) %>%
rename(pv4 = PV4.Dim1) %>%
rename(pv5 = PV5.Dim1) %>%
dplyr::glimpse()
## Rows: 5,173
## Columns: 6
## $ id_p <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19…
## $ pv1  <dbl> 0.95851632, -0.55205273, -0.01723044, -2.22503715, 0.79427132, 0.…
## $ pv2  <dbl> 0.6241367, -0.7769654, -0.9464132, -0.8843046, 0.9720189, 1.38405…
## $ pv3  <dbl> 0.35962742, -0.47125190, -0.62526205, -1.40351011, -0.17186591, 0…
## $ pv4  <dbl> 0.022843132, -0.222148324, 0.064553668, -0.888691272, 0.134836404…
## $ pv5  <dbl> 0.07612359, -1.44126180, -0.01245521, -1.39333463, 0.84176253, 0.…

# pv from a conditioned model
data_pri <- tam_pv_pri$pv %>%
rename(id_p = pid) %>%
rename(pc1 = PV1.Dim1) %>%
rename(pc2 = PV2.Dim1) %>%
rename(pc3 = PV3.Dim1) %>%
rename(pc4 = PV4.Dim1) %>%
rename(pc5 = PV5.Dim1) %>%
dplyr::glimpse()
## Rows: 5,173
## Columns: 6
## $ id_p <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19…
## $ pc1  <dbl> 1.44659068, 0.33371123, 0.45323547, -1.42832774, -0.03848333, 1.2…
## $ pc2  <dbl> 1.0647363, 0.1918385, -0.2655565, -1.6196104, 0.5239224, 0.704034…
## $ pc3  <dbl> 1.14873587, 0.14126066, 0.29772823, -0.94725353, 0.60044690, 0.74…
## $ pc4  <dbl> -0.3000956, -0.1046878, -0.2576709, -0.3175405, 0.1603241, 1.1569…
## $ pc5  <dbl> 0.96385676, -0.35377659, 0.59388303, -1.53314543, 0.76955750, 1.2…


# -----------------------------------------------
# theta realizations
# -----------------------------------------------

theta_wle   <- TAM::tam.wle(rasch_tam, progress = FALSE) %>%
               rename(id_p = pid) %>%
               rename(wle = theta) %>%
               rename(wle_se = error) %>%
               dplyr::select(id_p, wle, wle_se) %>%
               dplyr::glimpse()
## Rows: 5,173
## Columns: 3
## $ id_p   <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, …
## $ wle    <dbl> 0.70745545, -0.52017176, 0.06119417, -2.18746464, 0.37215291, 0…
## $ wle_se <dbl> 0.6106923, 0.5915351, 0.5631878, 0.6705852, 0.5809106, 0.610692…


theta_eap   <- data.frame(
               id_p = id_p_list,
               eap = rasch_tam$person$EAP,
               eap_sd = rasch_tam$person$SD.EAP
               ) %>%
               dplyr::select(id_p, eap, eap_sd) %>%
               dplyr::glimpse()
## Rows: 5,173
## Columns: 3
## $ id_p   <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, …
## $ eap    <dbl> 0.61986532, -0.40028157, 0.08268672, -1.72242550, 0.34455397, 0…
## $ eap_sd <dbl> 0.5328930, 0.5259641, 0.5068220, 0.5389681, 0.5173817, 0.532893…

# -----------------------------------------------
# create data with all theta realizaciones
# -----------------------------------------------

data_theta <- data_model %>%
              dplyr::left_join(., theta_wle, by = 'id_p') %>%
              dplyr::left_join(., theta_eap, by = 'id_p') %>%
              dplyr::left_join(., data_nul, by = 'id_p') %>%
              dplyr::left_join(., data_pri, by = 'id_p') %>%
              dplyr::glimpse()
## Rows: 5,173
## Columns: 69
## $ id_p     <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18…
## $ COUNTRY  <chr> "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL", "CHL"…
## $ IDCNTRY  <dbl+lbl> 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 15…
## $ IDSTUD   <dbl> 10010201, 10010202, 10010203, 10010204, 10010205, 10010206, 1…
## $ IDSCHOOL <dbl+lbl> 1001, 1001, 1001, 1001, 1001, 1001, 1001, 1001, 1001, 100…
## $ TOTWGTS  <dbl+lbl> 63.31969, 63.31969, 63.31969, 63.31969, 63.31969, 63.3196…
## $ JKZONES  <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, …
## $ JKREPS   <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, …
## $ sex      <dbl> 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, NA, 1, 0, 1, …
## $ dep      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
## $ mun      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
## $ sub      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
## $ pri      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
## $ LS2T01   <dbl+lbl>  4,  4,  4,  2,  2,  4,  3,  4,  4,  4,  4,  2,  4,  4,  …
## $ LS2T02   <dbl+lbl>  1, NA,  1,  3,  1,  1,  1,  1,  4,  1,  1,  1,  1, NA,  …
## $ LS2T03   <dbl+lbl> 3, 2, 3, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, …
## $ LS2T04   <dbl+lbl> 4, 4, 4, 4, 4, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, …
## $ LS2T05   <dbl+lbl> 4, 1, 3, 3, 1, 4, 1, 1, 4, 1, 1, 4, 3, 2, 1, 4, 2, 3, 1, …
## $ LS2T06   <dbl+lbl> 4, 2, 2, 1, 3, 3, 3, 4, 4, 4, 4, 4, 1, 1, 4, 1, 3, 3, 1, …
## $ LS2T07   <dbl+lbl> 3, 4, 3, 2, 4, 2, 4, 4, 3, 2, 4, 3, 2, 4, 4, 4, 3, 4, 2, …
## $ LS2T08   <dbl+lbl> 3, 3, 2, 2, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, …
## $ LS2T09   <dbl+lbl> 4, 2, 4, 4, 2, 2, 4, 4, 4, 2, 4, 4, 2, 3, 4, 2, 2, 3, 2, …
## $ LS2T10   <dbl+lbl>  1, NA,  1,  3,  3,  1,  2,  2,  2,  1,  2,  4,  1, NA,  …
## $ LS2T11   <dbl+lbl>  1,  2,  4,  2,  3,  1,  3,  1,  1,  1,  1,  1,  1,  1,  …
## $ LS2T12   <dbl+lbl> 3, 1, 1, 2, 4, 4, 2, 4, 2, 4, 4, 4, 2, 4, 4, 4, 1, 4, 1, …
## $ LS2T13   <dbl+lbl> 2, 1, 2, 3, 2, 2, 2, 2, 4, 2, 2, 2, 2, 1, 1, 1, 3, 1, 2, …
## $ LS2T14   <dbl+lbl> 1, 2, 1, 2, 1, 1, 3, 1, 1, 2, 1, 2, 1, 1, 4, 1, 4, 2, 1, …
## $ LS2T15   <dbl+lbl> 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 4, 4, …
## $ LS2T16   <dbl+lbl> 3, 2, 2, 4, 2, 2, 2, 2, 2, 2, 1, 4, 2, 1, 2, 2, 3, 2, 2, …
## $ y01      <dbl> 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, NA, 0, 0, 1, 0, …
## $ y02      <dbl> 1, NA, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, NA, 0, 1, 1, 1, 1, 1,…
## $ y03      <dbl> 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0…
## $ y04      <dbl> 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1…
## $ y05      <dbl> 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0…
## $ y06      <dbl> 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0…
## $ y07      <dbl> 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0…
## $ y08      <dbl> 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1…
## $ y09      <dbl> 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0…
## $ y10      <dbl> 1, NA, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, NA, 1, 1, 0, 1, 0, 1,…
## $ y11      <dbl> 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, NA, 1, 1, 1, …
## $ y12      <dbl> 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0…
## $ y13      <dbl> 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0…
## $ y14      <dbl> 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1…
## $ y15      <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0…
## $ y16      <dbl> 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1…
## $ test_sum <dbl> 11, 7, 9, 3, 11, 12, 5, 13, 9, 14, 12, 10, 11, 9, 10, 12, 5, …
## $ NWLCIV   <dbl+lbl> 154.5731, 145.1441, 144.8098, 133.0771, 160.5530, 154.487…
## $ KNOWLMLE <dbl+lbl>        NA,  93.71446,  89.42393,        NA,        NA,   …
## $ PV1CIV   <dbl+lbl> 547.3724, 404.3672, 505.3120, 321.2980, 530.5482, 461.148…
## $ PV2CIV   <dbl+lbl> 529.4967, 464.3032, 431.7064, 339.1737, 545.2694, 526.342…
## $ PV3CIV   <dbl+lbl> 521.0847, 454.8396, 481.1273, 330.7616, 494.7969, 453.788…
## $ PV4CIV   <dbl+lbl> 496.9000, 428.5519, 453.7881, 286.5982, 559.9905, 494.796…
## $ PV5CIV   <dbl+lbl> 577.8661, 408.5732, 497.9515, 319.1950, 596.7933, 439.067…
## $ ses      <dbl> 1.16665222, -1.17623742, 0.03919470, -0.77188999, -0.49257816…
## $ edu      <dbl> 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
## $ wle      <dbl> 0.70745545, -0.52017176, 0.06119417, -2.18746464, 0.37215291,…
## $ wle_se   <dbl> 0.6106923, 0.5915351, 0.5631878, 0.6705852, 0.5809106, 0.6106…
## $ eap      <dbl> 0.61986532, -0.40028157, 0.08268672, -1.72242550, 0.34455397,…
## $ eap_sd   <dbl> 0.5328930, 0.5259641, 0.5068220, 0.5389681, 0.5173817, 0.5328…
## $ pv1      <dbl> 0.95851632, -0.55205273, -0.01723044, -2.22503715, 0.79427132…
## $ pv2      <dbl> 0.6241367, -0.7769654, -0.9464132, -0.8843046, 0.9720189, 1.3…
## $ pv3      <dbl> 0.35962742, -0.47125190, -0.62526205, -1.40351011, -0.1718659…
## $ pv4      <dbl> 0.022843132, -0.222148324, 0.064553668, -0.888691272, 0.13483…
## $ pv5      <dbl> 0.07612359, -1.44126180, -0.01245521, -1.39333463, 0.84176253…
## $ pc1      <dbl> 1.44659068, 0.33371123, 0.45323547, -1.42832774, -0.03848333,…
## $ pc2      <dbl> 1.0647363, 0.1918385, -0.2655565, -1.6196104, 0.5239224, 0.70…
## $ pc3      <dbl> 1.14873587, 0.14126066, 0.29772823, -0.94725353, 0.60044690, …
## $ pc4      <dbl> -0.3000956, -0.1046878, -0.2576709, -0.3175405, 0.1603241, 1.…
## $ pc5      <dbl> 0.96385676, -0.35377659, 0.59388303, -1.53314543, 0.76955750,…

# -----------------------------------------------
# latent regression estimate
# -----------------------------------------------

# beta_{1}, and its SE
options(digits = 4)
TAM::tam.se(rasch_cov)$beta[2,]
## Item parameters
## |**********|
## |----------|
## Regression parameters
## |**|
## ||
## |--|
##   est.Dim1 se.Dim1
## 2   0.8708 0.04617

# knitr::kable(TAM::tam.se(rasch_cov)$beta[2,], digits = 5)

# Note: short code to extract the estimate
#       and its standard error. Unfortunately
#       the results display from TAM, does not
#       include a table with the estimates
#       and their standard error in the same table.
#       As such, one needs to extract the point
#       estimate and its standard error, by inspecting
#       the different outputs the library produces.
#
#       One way to inspect these elements is by using
#       dplyr::glimpse(tam_rasch) over the present
#       fitted tam object.

# -----------------------------------------------
# create survey object for simple random sample
# -----------------------------------------------

library(survey)
options(survey.lonely.psu="adjust")

data_srs <- survey::svydesign(
             data = data_theta,
             id = ~ 1
             )

# -----------------------------------------------
# pv conditioned
# -----------------------------------------------

lat_pvc <- mitools::withPV(
  mapping = pvciv ~ pc1 + pc2 + pc3 + pc4 + pc5, 
   data = data_srs,
   action = quote(survey::svyglm(pvciv ~ 1 + pri, design = data_srs)),
   rewrite=TRUE
   )

library(mitools)
options(digits = 4)
summary(mitools::MIcombine(lat_pvc))
## Multiple imputation results:
##       withPV.survey.design(mapping = pvciv ~ pc1 + pc2 + pc3 + pc4 + 
##     pc5, data = data_srs, action = quote(survey::svyglm(pvciv ~ 
##     1 + pri, design = data_srs)), rewrite = TRUE)
##       MIcombine.default(lat_pvc)
##              results      se   (lower  upper) missInfo
## (Intercept) 0.005583 0.01820 -0.03088 0.04204     29 %
## pri         0.867158 0.04449  0.77929 0.95502     17 %

# -----------------------------------------------
# pv unconditioned
# -----------------------------------------------

lat_pvn <- mitools::withPV(
  mapping = pvciv ~ pv1 + pv2 + pv3 + pv4 + pv5, 
   data = data_srs,
   action = quote(survey::svyglm(pvciv ~ 1 + pri, design = data_srs)),
   rewrite=TRUE
   )

library(mitools)
options(digits = 4)
summary(mitools::MIcombine(lat_pvn))
## Multiple imputation results:
##       withPV.survey.design(mapping = pvciv ~ pv1 + pv2 + pv3 + pv4 + 
##     pv5, data = data_srs, action = quote(survey::svyglm(pvciv ~ 
##     1 + pri, design = data_srs)), rewrite = TRUE)
##       MIcombine.default(lat_pvn)
##              results      se  (lower   upper) missInfo
## (Intercept) -0.09665 0.01923 -0.1355 -0.05783     34 %
## pri          0.63734 0.04182  0.5553  0.71940      7 %


# -----------------------------------------------
# regression on wle
# -----------------------------------------------

lat_wle <- survey::svyglm(wle ~ 1 + pri, design = data_srs)

options(digits = 4)
summary(lat_wle)
## 
## Call:
## svyglm(formula = wle ~ 1 + pri, design = data_srs)
## 
## Survey design:
## survey::svydesign(data = data_theta, id = ~1)
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  -0.1174     0.0178   -6.58    5e-11 ***
## pri           0.8264     0.0458   18.04   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## (Dispersion parameter for gaussian family taken to be 1.396)
## 
## Number of Fisher Scoring iterations: 2


# -----------------------------------------------
# regression on eap
# -----------------------------------------------

lat_eap <- survey::svyglm(eap ~ 1 + pri, design = data_srs)

options(digits = 4)
summary(lat_eap)
## 
## Call:
## svyglm(formula = eap ~ 1 + pri, design = data_srs)
## 
## Survey design:
## survey::svydesign(data = data_theta, id = ~1)
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  -0.0878     0.0138   -6.37  2.1e-10 ***
## pri           0.6402     0.0339   18.90  < 2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## (Dispersion parameter for gaussian family taken to be 0.826)
## 
## Number of Fisher Scoring iterations: 2
```

]
- Los valores obtenidos de $beta_1$ por medio de la regresión latente, son más parecidos a los obtenidos con el modelo que hace uso de los valores plausibles condicionados. En cambio, la regresión ajustada sobre los valores plausibles que provienen del modelo nulo (i.e., sin covariables) produce un estimados de menor tamaño. La diferencia entre el estimado de la regresión latente, con el estimado generado con los PV del modelo nulo, es de 5 veces el tamaño de los errores estándar del estimado de la regresión latente. Esta es una diferencia no ignorable.

- Otras opciones para ajustar este tipo de modelos consisten en emplear las realizaciones generadas de puntaje como #emph[weighted least estimate] (WLE) o como #emph[expected a posteriori] (EAP), y asjutar el modelo condicional deseado. En este ejemplo, entre estas dos opciones los WLE presentan una menor diferencia con los estimados generados con la regresión latente, en contraste a los estimados generados en dos pasos. Es decir, donde en un paso primero se generan puntajes del outcome de interés como realizaciones WLE, o como realizaciones EAP, y luego sobre estas realizaciones se ajusta el modelo condicional deseado.

- Estudios con simulaciones, plantean que los WLE sobre estiman la varianza original de $theta_p$, mientras que los EAP la subestiman. Por su parte los valores plausibles pueden recuperar este término, pero pueden subestimar a los estimados como en el ejemplo. Tradicionalmente, los estudios de gran escala, para producir puntajes de escalas de cuestionarios de contexto entregan los puntajes generados como WLE. Mientras que los puntajes de los test, son incluidos en las bases de datos como valores plausibles, generados de diferentes formas (ver Zheng, 2023).

#table(
  columns: 5,
  align: (left,right,right,right,right,),
  table.header([model], [e], [se], [point\_bias], [se\_bias],),
  table.hline(),
  [Latent regression], [0.8708], [0.0462], [0.0000], [0.0000],
  [PV conditioned], [0.8701], [0.0484], [-0.0007], [0.0023],
  [PV null], [0.6304], [0.0428], [-0.2404], [-0.0034],
  [WLE], [0.8264], [0.0458], [-0.0444], [-0.0004],
  [EAP], [0.6402], [0.0339], [-0.2306], [-0.0123],
)
#block[
#callout(
body: 
[
- `e` punto estimado generado por cada método
- `se` error estandar del estimado generado con cada método
- `point_bias` consiste en la diferencia entre el punto estimado generado por cada método empleado, y el generado por el metodo latente.
- `se_bias` consiste en la diferencia entre el error estándar asociado al estimado generado por cada método empleado, y el generado por el método de regresión latente.

]
, 
title: 
[
Nota
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
= Referencias
<referencias>
Adams, R. J. (2005). Reliability as a measurement design effect. Studies in Educational Evaluation, 31(2--3), 162--172. https:\/\/doi.org/10.1016/j.stueduc.2005.05.008

Agencia de la Calidad de la Educación. (2015). Estudio Internacional sobre Educación Cívica y Formación Ciudadana (ICCS): marco de evaluación y ejemplos de preguntas. http:\/\/archivos.agenciaeducacion.cl/Estudio\_Marco\_Evaluacion\_ICCS.pdf

Braun, H., & von Davier, M. (2017). The use of test scores from large-scale assessment surveys: psychometric and statistical considerations. Large-Scale Assessments in Education, 5(1), 17. https:\/\/doi.org/10.1186/s40536-017-0050-x

Brown, A., & Croudace, T. J. (2015). Scoring and Estimating Score Precision Using Multidimensional IRT Models. In S. P. Reise & D. A. Revicki (Eds.), Handbook of Item Response Theory Modeling: Applications to Typical Performance Assessment (pp.~307--333). Routledge.

Carrasco, D., Rutkowski, D., & Rutkowski, L. (2023). The advantages of regional large-scale assessments: Evidence from the ERCE learning survey. International Journal of Educational Development, 102(May), 102867. https:\/\/doi.org/10.1016/j.ijedudev.2023.102867

Diakow, R. (2013). Improving explanatory inferences from assessments \[University of California, Berkeley\]. http:\/\/escholarship.org/uc/item/4fc64449

De Boeck, P., Bakker, M., Zwitser, R., Nivard, M., Hofman, A., Tuerlinckx, F., & Partchev, I. (2011). The Estimation of Item Response Models with the lmer Function from the lme4 Package in R. Journal Of Statistical Software, 39(12), 1--28. https:\/\/doi.org/10.18637/jss.v039.i12

Goldstein, H., & Healy, M. J. R. (1995). The Graphical Presentation of a Collection of Means. Journal of Chemical Information and Modeling, 158(1), 175--177. https:\/\/doi.org/10.1017/CBO9781107415324.004

Hoffman, L. (2015). Longitudinal Analysis: Modeling Within-Person Fluctuation and Change. Psychology Press. http:\/\/www.pilesofvariance.com/

Kang, H. A., Su, Y. H., & Chang, H. H. (2018). A note on monotonicity of item response functions for ordered polytomous item response theory models. British Journal of Mathematical and Statistical Psychology, 71(3), 523--535. https:\/\/doi.org/10.1111/bmsp.12131

Luo, Y., & Dimitrov, D. M. (2019). A Short Note on Obtaining Point Estimates of the IRT Ability Parameter With MCMC Estimation in Mplus: How Many Plausible Values Are Needed? Educational and Psychological Measurement, 79(2), 272--287. https:\/\/doi.org/10.1177/0013164418777569

Masters, G. N. (1982). A rasch model for partial credit scoring. Psychometrika, 47(2), 149--174. https:\/\/doi.org/10.1007/BF02296272

Rabe-Hesketh, S., & Skrondal, A. (2012). Multilevel and Longitudinal Modeling Using Stata, Volumes I and II, Third Edition (3rd ed.). Stata Press.

Schulz, W., Ainley, J., & Fraillon, J. (2011). ICCS 2009 Technical Report (W. Schulz, J. Ainley, & J. Fraillon (eds.)). International Association for the Evaluation of Educational Achievement (IEA). http:\/\/www.iea.nl/fileadmin/user\_upload/Publications/Electronic\_versions/ICCS\_2009\_Technical\_Report.pdf

Singer, J. D., & Willett, J. B. (2003). Applied longitudinal data analysis: modeling change and event occurrence. Oxford University Press.

Skrondal, A., & Rabe-Hesketh, S. (2022). The Role of Conditional Likelihoods in Latent Variable Modeling. Psychometrika, 87(3), 799--834. https:\/\/doi.org/10.1007/s11336-021-09816-8

Sterba, S. K. (2009). Alternative Model-Based and Design-Based Frameworks for Inference From Samples to Populations: From Polarization to Integration. In Multivariate Behavioral Research (Vol. 44, Issue 6, pp.~711--740). https:\/\/doi.org/10.1080/00273170903333574

Pokropek, A. (2015). Phantom Effects in Multilevel Compositional Analysis: Problems and Solutions. Sociological Methods & Research, 44(4), 677--705. https:\/\/doi.org/10.1177/0049124114553801

Verhavert, S., De Maeyer, S., Donche, V., & Coertjens, L. (2018). Scale Separation Reliability: What Does It Mean in the Context of Comparative Judgment? Applied Psychological Measurement, 42(6), 428--445. https:\/\/doi.org/10.1177/0146621617748321

Wilson, M. (2023). Constructing Measures (2nd ed.). Routledge. https:\/\/doi.org/10.4324/9781003286929

Wind, S. A., & Hua, C. (2022). Rasch Measurement Theory Analysis in R. CRC Press, Taylor & Francis Group.

Wu, M. (2005). The role of plausible values in large-scale surveys. Studies in Educational Evaluation, 31(2--3), 114--128. https:\/\/doi.org/10.1016/j.stueduc.2005.05.005

Wu, M., Tam, H. P., & Jen, T.-H. (2016). Rasch Model (The Dichotomous Case). In Educational Measurement for Applied Researchers (pp.~109--138). Springer Singapore. https:\/\/doi.org/10.1007/978-981-10-3302-5\_7

Zheng, X. (2023). On generating plausible values for multilevel modelling with large-scale-assessment data. April, 1--25. https:\/\/doi.org/10.1111/bmsp.12326

== Anexo 1: opciones de respuesta y alternativas correctas
<anexo-1-opciones-de-respuesta-y-alternativas-correctas>
```r
#------------------------------------------------------------------------------
# key
#------------------------------------------------------------------------------

#------------------------------------------------
# item list
#------------------------------------------------

# LS2T01 = '[u] ORGANIZED CRIME                        '
# LS2T02 = '[u] DEALING WITH OPPOSITION GROUPS         '
# LS2T03 = '[u] TRAFFIC LAWS                           '
# LS2T04 = '[u] ALCOHOL AND TOBACCO SALES TO MINORS    '
# LS2T05 = '[u] VIOLENCE IN CONGRESS                   '
# LS2T06 = '[u] CONSEQUENCES OF LA DICTORSHIPS         '
# LS2T07 = '[u] CONSITITUTION DEFINITION               '
# LS2T08 = '[u] EQUAL EMPLOYMENT OPPORTUNITY           '
# LS2T09 = '[u] CONSEQUENCE OF LA VOTER APATHY         '
# LS2T10 = '[u] CHARACTERISTIC OF LA DICTATORSHIPS     '
# LS2T11 = '[u] RISK SITUATIONS FOR DEMOCRACY          '
# LS2T12 = '[u] DEMOCRATIC LEADERSHIP                  '
# LS2T13 = '[u] AUTHORITARAIN GOV CHARCTERISTIC        '
# LS2T14 = '[u] STATE RESPONSIBILITY FOR JUSTICE SYSTEM'
# LS2T15 = '[u] INDIGENOUS RIGHTS TO PRESERVE CULTURE  '
# LS2T16 = '[u] VOTING AS DEMOCRATIC PROCESS           '

#------------------------------------------------
# item key
#------------------------------------------------

# LS2T01 # Key = 4 .
# LS2T02 # Key = 1 .
# LS2T03 # Key = 3 .
# LS2T04 # Key = 4 .
# LS2T05 # Key = 1 .
# LS2T06 # Key = 4 .
# LS2T07 # Key = 3 .
# LS2T08 # Key = 3 .
# LS2T09 # Key = 2 .
# LS2T10 # Key = 1 .
# LS2T11 # Key = 1 .
# LS2T12 # Key = 4 .
# LS2T13 # Key = 2 .
# LS2T14 # Key = 1 .
# LS2T15 # Key = 4 .
# LS2T16 # Key = 2 .

#------------------------------------------------
# recode correct answer
#------------------------------------------------

rec_key <- function(x, key){
correct <- key
dplyr::case_when(
x == correct ~ 1,
x == 1 ~ 0, # A
x == 2 ~ 0, # B
x == 3 ~ 0, # C
x == 4 ~ 0, # D
TRUE ~ as.numeric(x))
}

#------------------------------------------------
# item 01 liberado
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T01)
```

#block[
```
[1] "ORGANIZED CRIME"
```

]
```r
dplyr::count(data_chl, LS2T01, rec_key(LS2T01, key = 4))
```

#block[
```
# A tibble: 5 × 3
  LS2T01                                   `rec_key(LS2T01, key = 4)`     n
  <dbl+lbl>                                                     <dbl> <int>
1  1 [IMPROVES THE FINANCES OF CITIZENS]                            0   407
2  2 [HELPS ALL CITIZENS TO FEEL SAFER]                             0  1871
3  3 [STRENGTHENS TRUST IN THE GOVERNMENT]                          0   442
4  4 [WEAKENS THE POWER OF THE STATE*]                              1  2402
5 NA                                                               NA    51
```

]
```r
knitr::include_graphics('./03_img/LS2T01_liberado.jpg')
```

#align(center)[#box(image("./03_img/LS2T01_liberado.jpg"))]
```r
#------------------------------------------------
# item 02
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T02)
```

#block[
```
[1] "DEALING WITH OPPOSITION GROUPS"
```

]
```r
dplyr::count(data_chl, LS2T02, rec_key(LS2T02, key = 1))
```

#block[
```
# A tibble: 5 × 3
  LS2T02                                        `rec_key(LS2T02, key = 1)`     n
  <dbl+lbl>                                                          <dbl> <int>
1  1 [ALLOWING THEM TO EXPRESS THEIR OPINIONS*]                          1  3906
2  2 [CHANGE MINDS AND JOIN THE GOVERN]                                  0   517
3  3 [OFFERING THEM JOBS IN THE PUBLIC SERVICE]                          0   534
4  4 [LEADERS TO SPEAK AGAINST THEM]                                     0   172
5 NA                                                                    NA    44
```

]
```r
#------------------------------------------------
# item 03
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T03)
```

#block[
```
[1] "TRAFFIC LAWS"
```

]
```r
dplyr::count(data_chl, LS2T03, rec_key(LS2T03, key = 3))
```

#block[
```
# A tibble: 5 × 3
  LS2T03                                        `rec_key(LS2T03, key = 3)`     n
  <dbl+lbl>                                                          <dbl> <int>
1  1 [TO PROM THE USE OF PUB TRANS]                                      0   464
2  2 [TO COLLECT FUNDS TO PAY FOR THE POLICE]                            0   116
3  3 [TO PROT THE SAFETY OF ROAD USERS*]                                 1  4398
4  4 [TO HELP PLAN THE CONSTRUCTION OF STREETS]                          0   182
5 NA                                                                    NA    13
```

]
```r
#------------------------------------------------
# item 04 Liberado
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T04)
```

#block[
```
[1] "ALCOHOL AND TOBACCO SALES TO MINORS"
```

]
```r
dplyr::count(data_chl, LS2T04, rec_key(LS2T04, key = 4))
```

#block[
```
# A tibble: 5 × 3
  LS2T04                                      `rec_key(LS2T04, key = 4)`     n
  <dbl+lbl>                                                        <dbl> <int>
1  1 [PREVENT YOUNG PEOPLE POLLUTING]                                  0   239
2  2 [YOUNG PEOPLE SHOULD SAVE THEIR MONEY]                            0   285
3  3 [BUYING ALCOHOL AND TOBACCO FOR PARENTS]                          0   146
4  4 [NOT MATURE ENOUGH TO MAKE DECISIONS*]                            1  4484
5 NA                                                                  NA    19
```

]
```r
knitr::include_graphics('./03_img/LS2T04_liberado.jpg')
```

#block[
#align(center)[#box(image("./03_img/LS2T04_liberado.jpg"))]
]
```r
#------------------------------------------------
# item 05
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T05)
```

#block[
```
[1] "VIOLENCE IN CONGRESS"
```

]
```r
dplyr::count(data_chl, LS2T05, rec_key(LS2T05, key = 1))
```

#block[
```
# A tibble: 5 × 3
  LS2T05                                        `rec_key(LS2T05, key = 1)`     n
  <dbl+lbl>                                                          <dbl> <int>
1  1 [DEPUTIES NOT BE RESPONSIBLE LEADERS*]                              1  2822
2  2 [<CONGRESS> IS SLOW TO APPROVE LAWS]                                0   324
3  3 [DEPUTIES CAN NEVER UNDERSTAND EACH OTHER]                          0  1193
4  4 [THE WAY DECISIONS CAN BE MADE]                                     0   819
5 NA                                                                    NA    15
```

]
```r
#------------------------------------------------
# item 06 liberado
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T06)
```

#block[
```
[1] "CONSEQUENCES OF LA DICTORSHIPS"
```

]
```r
dplyr::count(data_chl, LS2T06, rec_key(LS2T06, key = 4))
```

#block[
```
# A tibble: 5 × 3
  LS2T06                                      `rec_key(LS2T06, key = 4)`     n
  <dbl+lbl>                                                        <dbl> <int>
1  1 [SIGNIFICANT REDUCTION IN POVERTY]                                0  1165
2  2 [NEW IMMIGRANTS CAME]                                             0  1030
3  3 [COMMON CRIMINALS WERE SET FREE]                                  0  1067
4  4 [PEOPLE OF THE OPPOSITION HAD TO LEAVE*]                          1  1794
5 NA                                                                  NA   117
```

]
```r
knitr::include_graphics('./03_img/LS2T06_liberado.jpg')
```

#block[
#align(center)[#box(image("./03_img/LS2T06_liberado.jpg"))]
]
```r
#------------------------------------------------
# item 07
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T07)
```

#block[
```
[1] "CONSITITUTION DEFINITION"
```

]
```r
dplyr::count(data_chl, LS2T07, rec_key(LS2T07, key = 3))
```

#block[
```
# A tibble: 5 × 3
  LS2T07                             `rec_key(LS2T07, key = 3)`     n
  <dbl+lbl>                                               <dbl> <int>
1  1 [THE WORK CODE]                                          0   389
2  2 [THE CIVIL LAW CODE]                                     0  1531
3  3 [THE CONSTITUTION*]                                      1  1701
4  4 [THE INTERNATIONAL JUSTICE LAW]                          0  1518
5 NA                                                         NA    34
```

]
```r
#------------------------------------------------
# item 08
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T08)
```

#block[
```
[1] "EQUAL EMPLOYMENT OPPORTUNITY"
```

]
```r
dplyr::count(data_chl, LS2T08, rec_key(LS2T08, key = 3))
```

#block[
```
# A tibble: 5 × 3
  LS2T08                                     `rec_key(LS2T08, key = 3)`     n
  <dbl+lbl>                                                       <dbl> <int>
1  1 [NOT PUBLISHED ON ALL NEWSPAPERS]                                0   315
2  2 [SHOULD BE CARRIED OUT BY OLDER PEOPLE]                          0   979
3  3 [LIMITS THE ACCESS OF EMPLOYMENT*]                               1  3748
4  4 [CARRIED OUT BY WOMEN]                                           0   108
5 NA                                                                 NA    23
```

]
```r
#------------------------------------------------
# item 09
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T09)
```

#block[
```
[1] "CONSEQUENCE OF LA VOTER APATHY"
```

]
```r
dplyr::count(data_chl, LS2T09, rec_key(LS2T09, key = 2))
```

#block[
```
# A tibble: 5 × 3
  LS2T09                                 `rec_key(LS2T09, key = 2)`     n
  <dbl+lbl>                                                   <dbl> <int>
1  1 [REEMERGENCE OF AN ECONOMIC CRISIS]                          0   524
2  2 [WEAKENING OF DEMOCRATIC SYSTEMS*]                           1  2920
3  3 [INCREASE OF THE EMIGRATION RATE]                            0   483
4  4 [INCREASE OF AGE DISCRIMINATION]                             0  1224
5 NA                                                             NA    22
```

]
```r
#------------------------------------------------
# item 10
#------------------------------------------------


ilsa::variable_label(data_chl$LS2T09)
```

#block[
```
[1] "CONSEQUENCE OF LA VOTER APATHY"
```

]
```r
dplyr::count(data_chl, LS2T10, rec_key(LS2T09, key = 1))
```

#block[
```
# A tibble: 14 × 3
   LS2T10                                      `rec_key(LS2T09, key = 1)`     n
   <dbl+lbl>                                                        <dbl> <int>
 1  1 [LESS OPPORTUNITIES TO PARTICIPATE*]                              0  2158
 2  1 [LESS OPPORTUNITIES TO PARTICIPATE*]                              1   122
 3  1 [LESS OPPORTUNITIES TO PARTICIPATE*]                             NA     3
 4  2 [LESS PUBLIC RESOURCES ON PROMOTING ART]                          0   740
 5  2 [LESS PUBLIC RESOURCES ON PROMOTING ART]                          1   154
 6  2 [LESS PUBLIC RESOURCES ON PROMOTING ART]                         NA     1
 7  3 [OPPOSITION PARTIES HAD A BIGGER ROLE]                            0   910
 8  3 [OPPOSITION PARTIES HAD A BIGGER ROLE]                            1   132
 9  3 [OPPOSITION PARTIES HAD A BIGGER ROLE]                           NA     2
10  4 [CITIZENS HAD MORE TRUST IN GOVERN]                               0   737
11  4 [CITIZENS HAD MORE TRUST IN GOVERN]                               1   108
12 NA                                                                   0    82
13 NA                                                                   1     8
14 NA                                                                  NA    16
```

]
```r
#------------------------------------------------
# item 11
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T11)
```

#block[
```
[1] "RISK SITUATIONS FOR DEMOCRACY"
```

]
```r
dplyr::count(data_chl, LS2T11, rec_key(LS2T11, key = 1))
```

#block[
```
# A tibble: 5 × 3
  LS2T11                                     `rec_key(LS2T11, key = 1)`     n
  <dbl+lbl>                                                       <dbl> <int>
1  1 [THREATS AGAINST OPPOSITION*]                                    1  2569
2  2 [PROTEST FOR HIGHER WAGES]                                       0  1405
3  3 [THE GOVERNMENT INVITES UNITED NATIONS]                          0   524
4  4 [POLITICIANS DISAGREE FIGHTING CRIME]                            0   639
5 NA                                                                 NA    36
```

]
```r
#------------------------------------------------
# item 12
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T12)
```

#block[
```
[1] "DEMOCRATIC LEADERSHIP"
```

]
```r
dplyr::count(data_chl, LS2T12, rec_key(LS2T12, key = 4))
```

#block[
```
# A tibble: 5 × 3
  LS2T12                                    `rec_key(LS2T12, key = 4)`     n
  <dbl+lbl>                                                      <dbl> <int>
1  1 [MAKES DECISIONS EVERYONE AGREES WITH]                          0  1100
2  2 [DECISIONS TO BE MADE BY ALL PEOPLE]                            0  1257
3  3 [ADVISORS TO VOTE ON ALL ISSUES]                                0   911
4  4 [DIVERSE OPINIONS AND PERSPECTIVES*]                            1  1865
5 NA                                                                NA    40
```

]
```r
#------------------------------------------------
# item 13 liberado
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T13)
```

#block[
```
[1] "AUTHORITARAIN GOV CHARCTERISTIC"
```

]
```r
dplyr::count(data_chl, LS2T13, rec_key(LS2T13, key = 2))
```

#block[
```
# A tibble: 5 × 3
  LS2T13                                       `rec_key(LS2T13, key = 2)`     n
  <dbl+lbl>                                                         <dbl> <int>
1  1 [LESS NEED FOR POLICE OR ARMY]                                     0   774
2  2 [OPINIONS OF CITIZENS DO NOT INFLUENCE*]                           1  2938
3  3 [CITIZENS HAVE TO ENFORCE LAW THEMSELVES]                          0   752
4  4 [VOTE DIRECTLY IN THE <CONGRESS>]                                  0   654
5 NA                                                                   NA    55
```

]
```r
knitr::include_graphics('./03_img/LS2T13_liberado.jpg')
```

#block[
#align(center)[#box(image("./03_img/LS2T13_liberado.jpg"))]
]
```r
#------------------------------------------------
# item 14 liberado
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T14)
```

#block[
```
[1] "STATE RESPONSIBILITY FOR JUSTICE SYSTEM"
```

]
```r
dplyr::count(data_chl, LS2T14, rec_key(LS2T14, key = 1))
```

#block[
```
# A tibble: 5 × 3
  LS2T14                                  `rec_key(LS2T14, key = 1)`     n
  <dbl+lbl>                                                    <dbl> <int>
1  1 [STATE IS THE ONLY ONE IN CHARGE*]                            1  3276
2  2 [STEALING IS NOT AS BAD AS HITTING]                           0   694
3  3 [PUNISHMENT NOT SUFFICIENTLY SEVERE]                          0   522
4  4 [ONLY THE POLICE COULD HIT HIM]                               0   625
5 NA                                                              NA    56
```

]
```r
knitr::include_graphics('./03_img/LS2T14_liberado.jpg')
```

#block[
#align(center)[#box(image("./03_img/LS2T14_liberado.jpg"))]
]
```r
#------------------------------------------------
# item 15
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T15)
```

#block[
```
[1] "INDIGENOUS RIGHTS TO PRESERVE CULTURE"
```

]
```r
dplyr::count(data_chl, LS2T15, rec_key(LS2T15, key = 4))
```

#block[
```
# A tibble: 5 × 3
  LS2T15                                    `rec_key(LS2T15, key = 4)`     n
  <dbl+lbl>                                                      <dbl> <int>
1  1 [OPP TO CONTRIBUTE TO THE LABOR FORCE]                          0   293
2  2 [MORE LIKELY TO ATTRACT TOURISM]                                0   516
3  3 [MORE PUBLIC HOLIDAYS IN THE COUNTRY]                           0   264
4  4 [RIGHT TO MAINTAIN THEIR OWN CULTURE*]                          1  4063
5 NA                                                                NA    37
```

]
```r
#------------------------------------------------
# item 16
#------------------------------------------------

ilsa::variable_label(data_chl$LS2T16)
```

#block[
```
[1] "VOTING AS DEMOCRATIC PROCESS"
```

]
```r
dplyr::count(data_chl, LS2T16, rec_key(LS2T16, key = 2))
```

#block[
```
# A tibble: 5 × 3
  LS2T16                                   `rec_key(LS2T16, key = 2)`     n
  <dbl+lbl>                                                     <dbl> <int>
1  1 [TEACHER CHOOSES THE REPRESENTATIVE]                           0   262
2  2 [CLASS VOTES TO CHOOSE THE REPRES*]                            1  3687
3  3 [RAFFLE IS MADE TO CHOOSE THE REPRES]                          0   495
4  4 [THE BEST STD IN THE CLASS AS REPRES]                          0   688
5 NA                                                               NA    41
```

]
= Code time
<code-time>
#block[
```r
# ---------------------------------------- 
# estimated times
# ---------------------------------------- 

difftime(end_time, start_time, units="mins")
```

#block[
```
Time difference of 1.629 mins
```

]
]
= Agradecimientos
<agradecimientos>
- Muchos agradecemientos a David Torres Irribarra, y Dany Lopez por comentar y sugerir mejoras a la version de Abril de 6, de 2024.
