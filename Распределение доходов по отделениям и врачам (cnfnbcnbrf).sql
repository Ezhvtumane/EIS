select * from (
select
	case when CRFromFLD='' then CRFromD else CRFromFLD end As number,
	case when FLDctxtNameDocument like 'Паспортные%' 
			then (select txtNumberIB from IskStat2.dbo.istortable where DOCUNID = CRFromD) 
		when FLDctxtNameDocument like 'История%' 
			then RTRIM(SUBSTRING(SUBSTRING(FLDctxtNameDocument,0,CHARINDEX('(',FLDctxtNameDocument)),CHARINDEX('№',FLDctxtNameDocument)+2,500))
		else SUBSTRING(FLDctxtNameDocument,CHARINDEX('№',FLDctxtNameDocument)+2,500) end as numdoc,
	ctxtOtd2, ctxtPayDoctor2, Test,DTXTNameILL, FLDctxtNameDocument,IssKol,IssKolNazn,MyCost, MyCost*IssKol Summa,datDateVizit,kod2
		from IskStat2.dbo.PatientServices
			where datDateVizit between '2014' and '2015' and PayType=1
			) t where numdoc = '30173'
				order by dtxtnameill, number, FLDctxtNameDocument 
