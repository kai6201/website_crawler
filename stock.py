import requests
import pandas as pd
from bs4 import BeautifulSoup 
from selenium import webdriver
from selenium.webdriver.support.select import Select #下拉清單

#chrome_driver設定
chrome_path = "C:\selenium_driver_chrome\chromedriver.exe" #chromedriver.exe執行檔所存在的路徑
driver = webdriver.Chrome(chrome_path)

#網址設定
url='https://www.twse.com.tw/zh/page/trading/exchange/STOCK_DAY_AVG.html'

#前往該網頁
driver.get(url)

r = requests.get(url) #將此頁面的HTML GET下來
r.status_code #顯示200即為正常
soup = BeautifulSoup(r.text, 'html.parser') #以html的格式儲存






Select(driver.find_element_by_name("yy")).select_by_value('2012') #選擇年份
Select(driver.find_element_by_name("mm")).select_by_value('9') #選擇月份

inputs = driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/input').clear() #清空欄位
inputs = driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/input').send_keys("2891") #股票代碼_輸入
driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/a[2]').click() #執行

data = driver.find_element_by_xpath('//*[@id="report-table"]/tbody').text #開爬
data = pd.DataFrame(data.split("\n"))

data[['date','closing_price']] = data[0].str.split(expand=True)
data[['yy','mm','dd']] = data['date'].str.split('/',expand=True)
data = data.drop(columns=[0])

index = data['date'] != '月平均收盤價'
data = data[index]

data['stock_id'] = "2891"

data['closing_price'] = data['closing_price'].astype('float64')
date_list = ['yy','mm','dd']
for i in date_list:
    data[i] = data[i].astype('int64')
    



data['date'] 

pd.to_datetime(df)


data
type(data['date'])
data.dtypes


data1 = pd.DataFrame(data)






print(soup)
a1 = str(soup)
with open("test.txt","w") as f:
    f.write(a1)



a = str(soup)
print(a)
soup.head


a = "這是個測123！"
a = str(a)
with open("test.txt","w") as f:
    f.write(a)

