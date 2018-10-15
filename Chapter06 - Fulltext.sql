SELECT SERVERPROPERTY('IsFullTextInstalled');

-- Check which languages are supported in SQL Server.
SELECT lcid, name
FROM sys.fulltext_languages
ORDER BY name;

-- You can check current stopwords and stoplists in your database by using the following queries.
SELECT *
FROM sys.fulltext_stoplists;
SELECT stoplist_id, stopword, language
FROM sys.fulltext_stopwords;

-- Creating and Managing Full-Text Catalogs and Indexes