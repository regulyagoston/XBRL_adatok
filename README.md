# XBRL adatok

Amerikai tőzsdén jegyzett vállalatok adatai -- XBRL

## Adatok elérhetősége

US SEC honlapon ingyenesen elérhető adatok negyedéves felbontásban 2009-től.

- https://www.sec.gov/dera/data/financial-statement-data-sets

Bevezető anyagok az XBRL világába (angolul)

- [FASB videó](https://www.fasb.org/academics#section-5)
- [XBRL honlap](https://xbrl.us/home/use/filings-database/)
- [SEC dokumentáció](https://www.sec.gov/files/aqfs.pdf)
- [Chen et al (2022): Predicting Future Earnings Changes Using Machine Learning and Detailed Financial Data](https://onlinelibrary.wiley.com/doi/full/10.1111/1475-679X.12429)
  - [Kódok és további info](https://www.chicagobooth.edu/research/chookaszian/journal-of-accounting-research/online-supplements-and-datasheets/volume-60)


# Éves jelentés: 10-K

Példa az éves leadott jelentése az Apple Inc által benyújtott jelentés:

  - https://www.sec.gov/ixviewer/ix.html?doc=/Archives/edgar/data/320193/000032019323000106/aapl-20230930.htm

Minden pirossal alá és felé húzott vonalú elem megjelenik az adatokban. Ezekre kattintva megjelenik ay XBRL formátumban mentett adat tulajdonságai.
Ezt a reportot a (`codes/apple_example.R`)[https://github.com/regulyagoston/XBRL_adatok/blob/main/codes/apple_example.R] kód reprodukálja.


Össze lehet gyűjteni az összes éves jelentést. Ezt a (`codes/collect_data_example.R`)[https://github.com/regulyagoston/XBRL_adatok/blob/main/codes/collect_data_examp.R] mutatja. Itt az elérési utak átirása után a `type_gather` váltoyót "10K"-re kell állitani.

# További hasznos információk

SEC honlap, fontos részek:

  - Cégkeresés [https://www.sec.gov/edgar/searchedgar/companysearch]
  - CIK szám - adatok: [https://www.sec.gov/Archives/edgar/cik-lookup-data.txt]
  - Letöltött adatok dimenziói: [https://www.sec.gov/files/aqfs.pdf]

Beküldött jelentések/formok

  - 8-K form különböző nem tervezett eseményeket tartalmaz, ami az részvénytulajdonosok számára fontos lehet (pl: csőd, tőke átstruktúrálás, felvásárlás, stb.)
  - S-4 form a különböző felvásárlásokat és összeolvadásokat tartamazó dokumentum.

További hasznos források:

  - Fama-French iparági klasszifikáció: 
      - 48 klasszifikáció: [https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_48_ind_port.html]
      - 12 klasszifikáció: [https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_12_ind_port.html]
      - 30 klasszifikáció: [https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_30_ind_port.html]
  - Yahoo adatok [https://finance.yahoo.com/]
    - `tidyquant` csomaggal elérhető    
  - R-kódok cégek pénzügyi elemzésekhez [https://www.tidy-finance.org/]
  - R-csomag pénzügyi sorokkal való munkához: [https://business-science.github.io/tidyquant/]
    - különösen: [https://business-science.github.io/tidyquant/articles/TQ01-core-functions-in-tidyquant.html]
  - R-kódolás általánosságban [https://github.com/gabors-data-analysis/da-coding-rstats]
