import requests
import time
import pandas as pd
from bs4 import BeautifulSoup 
from selenium import webdriver
from selenium.webdriver.support.select import Select #下拉清單
from tqdm import tqdm

#chrome_driver設定
chrome_path = "C:\selenium_driver_chrome\chromedriver.exe" #chromedriver.exe執行檔所存在的路徑
driver = webdriver.Chrome(chrome_path)

#網址設定
url='https://www.twse.com.tw/zh/page/trading/exchange/STOCK_DAY_AVG.html'

#前往該網頁
driver.get(url)

time.sleep( 3 )

year_list = ['2015','2016','2017','2018','2019']
month_list = ['1','2','3','4','5','6','7','8','9','10','11','12']
stock_id = pd.read_csv('stock_id.csv')['id'].astype(object)

for y in year_list:
    data_final = pd.DataFrame()
    Select(driver.find_element_by_name("yy")).select_by_value(y) #選擇年份

    for m in month_list:
        Select(driver.find_element_by_name("mm")).select_by_value(m) #選擇月份

        for s in tqdm(range(len(stock_id))):
            inputs = driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/input').clear() #清空欄位
            inputs = driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/input').send_keys(stock_id[s]) #股票代碼_輸入
            driver.find_element_by_xpath('//*[@id="main-form"]/div/div/form/a[2]').click() #執行

            time.sleep( 3 )

            data = driver.find_element_by_xpath('//*[@id="result-message"]').text #是否有值
            if data == "": #沒有查詢不到的話
                data = driver.find_element_by_xpath('//*[@id="report-table"]/tbody').text #開爬
                data = pd.DataFrame(data.split("\n"))

                data[['date','closing_price']] = data[0].str.split(expand=True)
                data[['yy','mm','dd']] = data['date'].str.split('/',expand=True)

                data = data.drop(columns=[0])

                index = data['date'] != '月平均收盤價'
                data = data[index]

                data['stock_id'] = stock_id[s]

                index = data['closing_price'] == '--'
                data['closing_price'][index] = '0.00'
                data['closing_price'] = data['closing_price'].apply(lambda x: x.replace(',',''))
                data['closing_price'] = data['closing_price'].astype('float64')

                date_list = ['yy','mm','dd']
                for i in date_list:
                    data[i] = data[i].astype('int64')
                
                data_final = data_final.append(data)

                print(' stock_id:',stock_id[s],'year:',y,'month:',m)

            else:
                print(' stock_id:',stock_id[s],'year:',y,'month:',m,'is null')
     
        data_final.to_hdf('stock_{}_{}m.h5'.format(y,m),key='s')