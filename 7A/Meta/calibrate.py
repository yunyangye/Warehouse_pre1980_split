# -*- coding: utf-8 -*-
"""
Created on Thu Jul 26 19:24:33 2018

@author: yunyangye
"""
from xgboost import XGBRegressor
from sklearn.metrics import mean_squared_error
from sklearn.cross_validation import train_test_split
import csv

#################################################
# this package is used to train and test meta models,
# and then select the best solution
#################################################

# X is the data set of variables (inputs)
# y is the data set of the energy data (output)
def meta_xgboost(X,y,X_sample):
    # split the training set and testing set
    seed = 7
    test_size = 0.33
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=test_size, random_state=seed)

    # train the meta model
    model = XGBRegressor()
    model.fit(X_train, y_train)
    
    # test the meta model
    y_pred = model.predict(X_test)
    
    result = []
    for ind,val in enumerate(y_test):
        result.append([val,y_pred[ind]])
    with open('./results/meta_results.csv', 'a') as csvfile:
        data = csv.writer(csvfile, delimiter=',')
        for row in result:
            data.writerow(row)
    
    y_test_num = []
    for y in y_test:
        y_test_num.append(float(y))
        
    # calculate the Mean Squared Error
    mse = mean_squared_error(y_test_num, y_pred)
    
    # generate the output set of brute force sample set
    Y_xgboost = model.predict(X_sample)
    
    return Y_xgboost, mse

