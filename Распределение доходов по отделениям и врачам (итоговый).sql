declare @bd date
declare @ed date
set @bd = '01.08.2015'
set @ed = '31.08.2015'


/*
�� ��������� ������� #t_prices ���������� ���� ������ � �� ���. ����� ����� ��������� (�� PLH_Code) ����.
*/
/*
select MSR_UsrCode,p.PLH_Price into #t_prices
	from 
	(
	select MSR_UsrCode,MAX(PLH_Code) kod
		from finance.dbo.medservice m 
			inner join finance.dbo.pricehistory p
		 		on MSR_Delete!=1 and PLH_Fixed = 1 and MSR_Code = PLH_MSR_Code
		group by  MSR_UsrCode
	) t 
		left join finance.dbo.pricehistory p on t.kod=p.PLH_Code
		*/
/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

/*
������ �� �� � �� �� ����. 
����� �� �������� �������� #t_eis
*/
--����������� ���������

select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_BEGIN, DATE_END, sumib, kolIB,kolsly4,1 flag 
--into #t_eis 
	from 
	(
	select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_BEGIN, DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  
		from
		(
		select DEPT_NAME,ILL_HISTORY,t3.ID_CASE, t3.DATE_BEGIN, t3.DATE_END, sum(service_cost) cost, COUNT(*) kol 
			from OPENquery(EISS, 'select * from case_services_accounts ') t
				left join 
				(
				select * from OPENquery(EISS, 'select * from CASE_SERVICES') 
				) t1 on  t.ID_ACCOUNT=t1.ID_ACCOUNT
				left join
				(
				select * from OPENquery(EISS, 'select * from CASES')
				) t3 on t1.ID_CASE=t3.ID_CASE
				left join 
				(
				select * from OPENquery(EISS, 'select * from VMU_MU_DEPTS')
				) t2 on t1.ID_DEPT=t2.ID_DEPT
		where account_date between @bd and @ed
		group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END,t3.DATE_BEGIN
		) t
	group by DEPT_NAME,ILL_HISTORY, ID_CASE,DATE_END,DATE_BEGIN
	) t

--������ ���������
insert into #t_eis 
/*
� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
*/
select DEPT_NAME, ILLH,ID_CASE, DATE_BEGIN, DATE_END, cost, 1 kolib ,1 kolsly4,-1 flag  
	from
	(
	select 
		DEPT_NAME, 
		case when t2.DATE_BEGIN IS null then t22.DATE_BEGIN else t2.DATE_BEGIN end DATE_BEGIN,
		case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end DATE_END,
		case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
		case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,												
		SUMM_REFUSE cost
	from OPENquery(EISS,'select * from REFUSES ') t			
/*
ACT_DATE  ��� ���� ��� � ���, � ReFUSE_DATE ��� ���� ��. 
ACT_MODE �� ����, ��� �� ���� 0, �� � ���� ������ �� �����, �������� ������.
���� - ID_REFUSE
*/
	left join
	(
	select * from OPENquery(EISS, 'select * from REFUSES_OBJ ')																				
	)t1 on t.ID_REFUSE=t1.ID_REFUSE
/*
������ � ID_CASE � ID_SERVICE � ������ ������. 
��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. UPD:
�� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
(�������� � ������)
*/
	left join 
	(
	select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_BEGIN, DATE_END from OPENquery(EISS, 'select * from CASES')												
	group by ID_DEPT, ID_CASE, ILL_HISTORY, DATE_BEGIN,DATE_END
	) t2 on  t1.ID_CASE=t2.ID_CASE
/*
������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
*/
	left join 
	(
	select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_BEGIN, t1.DATE_END from OPENquery(EISS, 'select * from CASE_SERVICES') t
		left join 
			(
			select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_BEGIN,DATE_END from OPENquery(EISS, 'select * from CASES') 
			)t1 on t.ID_CASE=t1.ID_CASE
	) t22 on  t1.ID_SERVICE=t22.ID_SERVICE
/*
� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
*/																									
	left join 
	(
	select * from OPENquery(EISS, 'select * from VMU_MU_DEPTS')
	) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT		
/*
��� ��� ������� - �������� ���������.
*/																			
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 																																		
) t

--����������� �����������
insert into #t_eis 
	select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_BEGIN,DATE_END,sumib,kolIB,kolsly4,1 flag 
		from 
		(
		select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_BEGIN, DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  
			from
			(
			select DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_BEGIN,t3.DATE_END, sum(service_cost) cost, COUNT(*) kol from OPENquery(EIS, 'select * from case_services_accounts ') t
				left join 
				(
				select * from OPENquery(EIS, 'select * from CASE_SERVICES') 
				) t1 on  t.ID_ACCOUNT=t1.ID_ACCOUNT
				left join
				(
				select * from OPENquery(EIS, 'select * from CASES') 
				) t3 on t1.ID_CASE=t3.ID_CASE
				left join 
				(
				select * from OPENquery(EIS, 'select * from VMU_MU_DEPTS')
				) t2 on t1.ID_DEPT=t2.ID_DEPT
			where account_date between @bd and @ed
			group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END,t3.DATE_BEGIN
			) t
		group by DEPT_NAME, ILL_HISTORY, ID_CASE, DATE_BEGIN,DATE_END
		) t

--������ �����������
insert into #t_eis 
	select DEPT_NAME,ILLH,ID_CASE, DATE_BEGIN, DATE_END, cost,1 kolib,1 kolsly4,-1 flag 
		from
		(
		select 
		DEPT_NAME,
		case when t2.DATE_BEGIN IS null then t22.DATE_BEGIN else t2.DATE_BEGIN end DATE_BEGIN,
		case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end DATE_END,
		case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
		case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														
		SUMM_REFUSE cost 
		from OPENquery(EIS,'select * from REFUSES') t																							
			left join
			(
			select * from OPENquery(EIS, 'select * from REFUSES_OBJ ')																				
			)t1 on t.ID_REFUSE=t1.ID_REFUSE																											
			left join 
			(
			select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END,DATE_BEGIN from OPENquery(EIS, 'select * from CASES')														
			group by ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END,DATE_BEGIN
			) t2 on  t1.ID_CASE=t2.ID_CASE
			left join 
			(
			select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_BEGIN, t1.DATE_END from OPENquery(EIS, 'select * from CASE_SERVICES') t
				left join 
				(
				select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_BEGIN, DATE_END from OPENquery(EIS, 'select * from CASES') 
				)t1 on t.ID_CASE=t1.ID_CASE
			) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									
			left join 
			(
			select * from OPENquery(EIS, 'select * from VMU_MU_DEPTS')
			) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT																					
		where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 
		) t


/*
�� ��������� ������� #t_services ���������� ������ (������ � ��� ������������ ����, ����� ������� ����-���� ���), ���������� �� ���� FLDctxtNameDocument ����� ��,�� � ��. 
� �����-���� ������ CRFromFLD �� CRFromD, ��� ��� ��� ����������� �� ��, � ����� �� ����� �� istortable �� DOCUNID�.
*/

select number,numdoc,ctxtOtd2, ctxtPayDoctor2, Test,DTXTNameILL, FLDctxtNameDocument,IssKol,IssKolNazn,MyCost, MyCost*IssKol Summa,datDateBegin,datDateVizit,Kod2,paytype,PLH_Price
--ILL_HISTORY, DATE_BEGIN, DATE_END, [sum],kolsly4 
	--into #t_services
		from 
		(
		select
			case when CRFromFLD='' then CRFromD else CRFromFLD end as number,
			case when FLDctxtNameDocument like '����������%' 
					then (select txtNumberIB from IskStat2.dbo.istortable where DOCUNID = CRFromD) 
				when FLDctxtNameDocument like '�������%' 
					then RTRIM(SUBSTRING(SUBSTRING(FLDctxtNameDocument,0,CHARINDEX('(',FLDctxtNameDocument)),CHARINDEX('�',FLDctxtNameDocument)+2,500))
				else SUBSTRING(FLDctxtNameDocument,CHARINDEX('�',FLDctxtNameDocument)+2,500) end as numdoc,
			ctxtOtd2, ctxtPayDoctor2, Test,DTXTNameILL, FLDctxtNameDocument,IssKol,IssKolNazn,MyCost, MyCost*IssKol Summa,datDateVizit,Kod2,paytype, datDateBegin
				from IskStat2.dbo.PatientServices p 
		) p
				full join
				#t_prices mp on p.Kod2=mp.MSR_UsrCode
				
				/*right join
				(
				select ILL_HISTORY, DATE_BEGIN, DATE_END, sum(sumib*flag) [sum],kolsly4 from #t_eis 
				group by ILL_HISTORY, DATE_BEGIN, DATE_END, kolsly4
				) eis on p.numdoc collate Cyrillic_General_CI_AS = eis.ILL_HISTORY --and p.datDateBegin=eis.DATE_BEGIN and p.datDateBegin=eis.DATE_END and eis.ILL_HISTORY='6823'*/
					--where datDateVizit between (select (convert(date,DATE_BEGIN,104)) from #t_eis where numdoc collate Cyrillic_General_CI_AS = ILL_HISTORY) and (select convert(date,DATE_END,104) from #t_eis where numdoc collate Cyrillic_General_CI_AS =ILL_HISTORY)-- and  numdoc = ((select ILL_HISTORY from #t_eis)) 
					where numdoc='5126' --'7994'
						order by dtxtnameill, number, FLDctxtNameDocument 



--drop table #t_eis
--drop table #t_services
--drop table #t_prices

--select * from #t_services order by numdoc



select ILL_HISTORY,ID_CASE, COUNT(*) z from #t_eis 
where DEPT_NAME not like '���������������' --and ill_history='7994'
group by ILL_HISTORY,ID_CASE 

order by ILL_HISTORY


select * from OPENquery(EISS, 'select * from CASES') WHERE ill_history='7490' ID_CASE in ('7230.12865','7230.12842','7230.12864')
select * from OPENquery(EISS, 'select * from PATIENT_DATA') WHERE ID_PATIENT in ('7230.12251','7230.12272')
