* First import the data;
proc import datafile="G:\Project Jstarts\Courses\Statistical Data Analysis with SAS\data\asia.xlsx" 
dbms=xlsx out=asia;
run;
proc import datafile="G:\Project Jstarts\Courses\Statistical Data Analysis with SAS\data\europe.xlsx"
dbms=xlsx out=europe;
run;
proc import datafile="G:\Project Jstarts\Courses\Statistical Data Analysis with SAS\data\usa.xlsx"
dbms=xlsx out=usa;
run;
proc import datafile="G:\Project Jstarts\Courses\Statistical Data Analysis with SAS\data\carspec.xlsx"
dbms=xlsx out=carspec;
run;


* Concatenation;
data allregion;
	length MAKE $13 MODEL $39;
	set asia europe usa;
run;

* Merge;
proc sort data=allregion;
	by MAKE MODEL;
run;

proc sort data=carspec;
	by MAKE MODEL;
run;

data cars;
	merge allregion carspec;
	by MAKE MODEL;
run;


* investigate the categorical variables;
proc freq data=cars;
	tables MAKE TYPE Origin DriveTrain;
run;




* Introduction - this is to give you an idea of how a predictive modeling process is like but will not be practiced in this course;

* Normally, before a modeling process, PROC CORR is usually utilized to investigate the relationship among variables, so that we eliminate them to 
reduce the dimension.;
* And recall the assumption for linear regression, one of the most important assumption is that the distribution of independent variable is normally distributed,
what is it is not? We should use PROC UNIVARIATE to check the normality of each numeric variable, and if it is not normally distributed, we will need to transform 
it first. This is out of scope of this course;
* The missing values might need to be imputed before passing into the model because PROC REG will only consider a full case analysis, i.e. all predictors
have to be non-missing, otherwise the record will be excluded and with less records, the statistical power is reduced;
* In a typical predictive modeling process, the input data will be divided into at least two parts: training data set, and validation data set. In order to 
fully represent the data, we need to learn about the sampling technique, which is also out of scope of this course.;
* During the modeling process, if you want SAS to pick out variables that are significantly impacted the model, you can search for selection= option, it has stepwise, forward and backward.
SAS will select the variables that have p value meeting the preset criteria.;
* There are in fact much more contents for predictive modeling and this is not the focus of this course, instead, we should focus on statistical analysis to
trully understand the data first.;

data prepare;
	set cars;
* extract the number of doors;
	label Noofdr = "Number of doors";
	* method 1;
	/*if find(MODEL, "1dr") then Noofdr = 1;
	else if find(MODEL, "2dr") then Noofdr = 2;
	else if find(MODEL, "3dr") then Noofdr = 3;
	else if find(MODEL, "4dr") then Noofdr = 4;
	else if find(MODEL, "5dr") then Noofdr = 5;*/
	* method 2;
	if find(MODEL, "dr") and not find(MODEL, "dra") then do;
		Noofdr = input(substr(MODEL, find(MODEL, "dr") - 2, 2), best.);
	end;
* Fuel economy;
	Fuel_eco = MPG_City * .55 + MPG_Highway * .45;


* Make dummies for each make - This is only when you want to account for the make, because there are so many makes and makes the regression complex;
	array _charval (38) $200 _temporary_ ("Acura" "Audi" "BMW" "Buick" "Cadillac" "Chevrolet" "Chrysler" "Dodge" "Ford" "GMC"
						"Honda" "Hummer" "Hyundai" "Infiniti" "Isuzu" "Jaguar" "Jeep" "Kia" "Land Rover"
						"Lexus" "Lincoln" "MINI" "Mazda" "Mercedes-B" "Mercury" "Mitsubishi" "Nissan"
						"Oldsmobile" "Pontiac" "Porsche" "Saab" "Saturn" "Scion" "Subaru" "Suzuki" "Toyota"
						"Volkswagen" "Volvo");

	array _var (*) Acura Audi BMW Buick Cadillac Chevrolet Chrysler Dodge Ford GMC 
					Honda Hummer Hyundai Infiniti Isuzu Jaguar Jeep Kia Land_Rover 
					Lexus Lincoln MINI Mazda Mercedes Mercury Mitsubishi Nissan
					Oldsmobile Pontiac Porsche Saab Saturn Scion Subaru Suzuki Toyota
					Volkswagen Volvo;

	do i = 1 to dim(_var);
		if MAKE = _charval(i) then _var(i) = 1;
		else _var(i) = 0;
	end;

* Make dummies for Type;
	array _type (6) $200 _temporary_ ("Hybrid" "SUV" "Sedan" "Sports" "Truck" "Wagon");
	array _typevar (6) Hybrid SUV Sedan Sports Truck Wagon;
	do i = 1 to 6;
		if TYPE = _type(i) then _typevar(i) = 1;
		else _typevar(i) = 0;
	end;

* Make dummies for origin;
	array _origin (3) $200 _temporary_ ("Asia" "Euro" "USA");
	array _origvar (3) Asia Euro USA;
	do i = 1 to 3;
		if ORIGIN = _origin(i) then _origvar(i) = 1;
		else _origvar(i) = 0;
	end;

* Make dummies for DriveTrain;
	array _DriveTrain (3) $200 _temporary_ ("All" "Front" "Rear");
	array _DTvar (3) ALL FRONT REAR;
	do i = 1 to 3;
		if DriveTrain = _DriveTrain(i) then _DTvar(i) = 1;
		else _DTvar(i) = 0;
	end;	
	drop i;
run;


* First we include every variable;
proc reg data=prepare;
model MSRP = EngineSize -- REAR;
run;
quit;
* Comment: turn out that we do not have enough number of observations so parameters with DF=B are biased;

* Try out the make first;
proc reg data=prepare;
model MSRP = Acura -- Volvo;
run;
quit;


* Try out other variables;
proc reg data=prepare;
model MSRP = EngineSize -- Fuel_eco Hybrid -- REAR;
run;
quit;
* MPG_CITY MPG_HIGHWAY are grouped into one variable Fuel_eco, and they are biased, so we remove them;


* Try out the rest;
proc reg data=prepare;
model MSRP = EngineSize -- Horsepower Weight--Fuel_eco Hybrid -- REAR;
run;
quit;
* There are still a few that are biased. What we can do now is that we only take those with large parameter estimates with significant p-value because they 
have the largest impact on the dependent variables, and remove the dummies;

* Try out the large parameter estimates;
proc reg data=prepare;
model MSRP = EngineSize -- Horsepower Weight--Fuel_eco;
run;
quit;
* Length and Weight can be removed because of their low parameter estimates;
proc reg data=prepare;
model MSRP = EngineSize -- Horsepower Wheelbase Noofdr Fuel_eco;
run;
quit;
* Wheelbase becomes insignificant now remove;
proc reg data=prepare;
model MSRP = EngineSize -- Horsepower Noofdr Fuel_eco;
run;
quit;

* Now we have a model with a few variables that will give a decent estimate of the MSRP, with a adj R-sq = 0.7549;


* This does not mean that the dummies are useless, we can still extract info from them, for example, the make;
proc reg data=prepare;
model MSRP = Acura -- Volvo;
run;
quit;
* Mercedes = 0 is the reference, i.e. the intercept is the average price for Mercedes. and looking at each parameter estimate, it means 
how much it is from Mercedes. For example, the average price for Toyota is $-38132 from the average parice of Mercedes ($60657).;
* You can try out different combination of predictor variables and see how that impacts the price, and that will provide answers your questions.;

