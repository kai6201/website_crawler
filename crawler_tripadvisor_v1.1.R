library(rio)
library(RSelenium)
library(rvest)
library(tidyverse)

#cmd執行
# cd C:\Program Files (x86)\Google\Chrome\Application
# java -jar selenium-server-standalone-3.141.59.jar

#遠端連線
rs.crawler <- remoteDriver(remoteServerAddr = "localhost", port = 4444, browserName = "chrome")

rs.crawler$open()
rs.crawler$navigate("https://www.tripadvisor.com.tw/Attraction_Review-g13808515-d2019764-Reviews-Elephant_Mountain_aka_Nangang_District_Hiking_Trail-Xinyi_District_Taipei.html")

#頁數計算
rs.crawler_pagenum <- rs.crawler$findElement(using = "class", "pageNumbers")$getElementText()
rs.crawler_pagenum <- rs.crawler_pagenum %>% unlist()
if(grepl("…[0-9]+",rs.crawler_pagenum))
{
  page_limit <- regmatches(rs.crawler_pagenum,regexec("…[0-9]+",rs.crawler_pagenum))
  page_limit <- sub("…","",page_limit) %>% as.integer()
}else{
  page_limit <- substr(rs.crawler_pagenum,nchar(rs.crawler_pagenum),nchar(rs.crawler_pagenum))
  page_limit <- page_limit %>% as.integer()
}

#爬取標題
rs.crawler_text <- rs.crawler$findElement(using = "id", "HEADING")
title_main <- rs.crawler_text$getElementAttribute("outerHTML")[[1]] %>% read_html() %>% html_text()

score_class <- c("50","40","30","20","10")
score_selector <- "div > div.ui_column.is-9 > span.ui_bubble_rating.bubble_score"
comment_sum <- as.character()
for( page in 1:page_limit)
{
  #點選所有語言
  rs.crawler_langu <- rs.crawler$findElement(using = "xpath", "//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[4]/div/div[2]/div[1]/div[1]/label")
  rs.crawler_langu$clickElement()
  
  Sys.sleep(2)
  
  #點選更多
  rs.crawler_more <- rs.crawler$findElements(using = "class", "reviewSelector")
  
  rs.crawler_more.list <- unlist(lapply(rs.crawler_more, function(x) { x$getElementAttribute("id") }))
  rs.crawler_more.exist <- grepl("review_[0-9]+",rs.crawler_more.list)
  rs.crawler_more.list <- rs.crawler_more.list[rs.crawler_more.exist]
  
  rs.crawler_more.text <- unlist(lapply(rs.crawler_more, function(x) { x$getElementText() }))
  rs.crawler_more.text <- rs.crawler_more.text[rs.crawler_more.exist]
  
  Sys.sleep(2)
  
  #判斷是否需要點擊
  for (each in 1:length(rs.crawler_more.list))
  {
    if(grepl("...更多\n",rs.crawler_more.text[each]))
    {
      if(grepl("\nGoogle 翻譯\n",rs.crawler_more.text[each]))
      {
        more_chr <- sub("review_number",replacement = rs.crawler_more.list[each],"//*[@id='review_number']/div/div[2]/div[3]/div/p/span")
        rs.crawler_more <- rs.crawler$findElement(using = "xpath", more_chr)
        rs.crawler_more$clickElement()
      }else{
        more_chr <- sub("review_number",replacement = rs.crawler_more.list[each],"//*[@id='review_number']/div/div[2]/div[2]/div/p/span")
        rs.crawler_more <- rs.crawler$findElement(using = "xpath", more_chr)
        rs.crawler_more$clickElement()
      }
      break
    }
  }
  
  Sys.sleep(2)
  
  #爬文!!
  for( i in 1:length(rs.crawler_more.list))
  {
    #選擇要爬文的範圍
    rs.crawler_text <- rs.crawler$findElement(using = "id", rs.crawler_more.list[i])
    web.text <- rs.crawler_text$getElementAttribute("outerHTML")[[1]] %>% read_html()
    #各欄位爬文
    title <- web.text %>% html_nodes(".noQuotes") %>% html_text()
    content <- web.text %>% html_nodes(".partial_entry") %>% html_text()
    author <- web.text %>% html_nodes("div.info_text > div:nth-child(1)") %>% html_text()
    country <- web.text %>% html_nodes("div.info_text > div:nth-child(2)") %>% html_text()
    date <- web.text %>% html_nodes(".ratingDate") %>% html_attr("title")
    url <- web.text %>% html_nodes(".title") %>% html_attr("href")
    url <- paste0("https://www.tripadvisor.com.tw",url)
    for (each in 1:length(score_class))
    {
      score_selector1 <- gsub("score",replacement = score_class[each],score_selector)
      score_data <- web.text %>% html_nodes(score_selector1) %>% html_text()
      if(is_empty(score_data)==FALSE)
      {
        score <- as.numeric(score_class[each])*2 
        break
      }
    }
    if(is_empty(title)){title <- NA}
    if(is_empty(content)){content <- NA} 
    if(is_empty(author)){author <- NA} 
    if(is_empty(country)){country <- NA} 
    if(is_empty(score)){score <- NA} 
    if(is_empty(date)){date <- NA}
    if(is_empty(url)){url <- NA}
    comment_temp <- cbind(title,content,author,country,score,date,url) %>% as_tibble()
    comment_sum <- rbind(comment_sum,comment_temp)
  }
  if(page == page_limit)
  {
    cat("Page:",page,"(",nrow(comment_sum),")\n")
    break
  }
  #換頁
  if(page == 1)
  {
    rs.crawler_page <- rs.crawler$findElement(using = "css", "div > div:nth-child(15) > div > div > a.nav.next.taLnk.ui_button.primary")
  }else{
    rs.crawler_page <- rs.crawler$findElement(using = "css", "div > div:nth-child(14) > div > div > a.nav.next.taLnk.ui_button.primary")
  }
  rs.crawler_page$clickElement()
  cat("Page:",page,"(",nrow(comment_sum),")\n")
  Sys.sleep(5)
}
comment_sum <- cbind(title_main,comment_sum)
#輸出
export_name <- paste0(title_main,".xlsx")
export(comment_sum,export_name)
