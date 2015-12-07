declare @bd date
declare @ed date
set @bd = '01.08.2015'
set @ed = '31.08.2015'

--����������� ���������
select DEPT_NAME, ILL_HISTORY,ID_CASE, YEAR(DATE_END) data,DATE_END, sumib, kolIB,kolsly4,1 flag 
into #t_eis 
from 
(
select DEPT_NAME, ILL_HISTORY,ID_CASE,DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  from(
select DEPT_NAME,ILL_HISTORY,t3.ID_CASE, t3.DATE_END, sum(service_cost) cost, COUNT(*) kol from OPENquery(EISS, 'select * from case_services_accounts ') t
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
group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END
) t
group by DEPT_NAME,ILL_HISTORY, ID_CASE,DATE_END
) t

--������ ���������
insert into #t_eis 
select DEPT_NAME, ILLH,ID_CASE, YEAR(data) data, data, cost, 1 kolib ,1 kolsly4,-1 flag  from
(
select DEPT_NAME, 
case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end data,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														/*
																																		� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
																																		� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
																																		����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
																																		*/
SUMM_REFUSE cost
from OPENquery(EISS,'select * from REFUSES ') t																							/*ACT_DATE  ��� ���� ��� � ���, � ReFUSE_DATE ��� ���� ��. 
																																		ACT_MODE �� ����, ��� �� ���� 0, �� � ���� ������ �� �����, �������� ������.
																																		���� - ID_REFUSE*/

left join
(
select * from OPENquery(EISS, 'select * from REFUSES_OBJ ')																				
)t1 on t.ID_REFUSE=t1.ID_REFUSE																											/*������ � ID_CASE � ID_SERVICE � ������ ������. 
																																		��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. UPD:
																																		�� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
																																		(�������� � ������)
																																		*/
left join 
(
select ID_DEPT,ID_CASE,ILL_HISTORY, DATE_END from OPENquery(EISS, 'select * from CASES')												/*
																																		������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
																																		*/
group by ID_DEPT, ID_CASE, ILL_HISTORY, DATE_END
) t2 on  t1.ID_CASE=t2.ID_CASE

																																		
left join 
(
select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_END from OPENquery(EISS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END from OPENquery(EISS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									/*
																																		� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
																																		������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
																																		� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
																																		*/
left join 
(
select * from OPENquery(EISS, 'select * from VMU_MU_DEPTS')
) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT																					/*
																																		��� ��� ������� - �������� ���������.
																																		*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 																																		
) t

--����������� �����������
insert into #t_eis select DEPT_NAME, ILL_HISTORY,ID_CASE, YEAR(DATE_END),DATE_END,sumib,kolIB,kolsly4,1 flag from 
(
select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  from(
select DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END, sum(service_cost) cost, COUNT(*) kol from OPENquery(EIS, 'select * from case_services_accounts ') t
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
group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END
) t
group by DEPT_NAME, ILL_HISTORY, ID_CASE, DATE_END
) t

--������ �����������
insert into #t_eis select DEPT_NAME,ILLH,ID_CASE, YEAR(DATE_END), DATE_END,cost,1 kolib,1 kolsly4,-1 flag from
(
select DEPT_NAME,t2.DATE_END,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														/*
																																		� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
																																		� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
																																		����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
																																		*/
SUMM_REFUSE cost 
from OPENquery(EIS,'select * from REFUSES') t																							/*ACT_DATE  ��� ���� ��� � ���, � ReFUSE_DATE ��� ���� ��. 
																																		ACT_MODE �� ����, ��� �� ���� 0, �� � ���� ������ �� �����, �������� ������.
																																		���� - ID_REFUSE*/

left join
(
select * from OPENquery(EIS, 'select * from REFUSES_OBJ ')																				
)t1 on t.ID_REFUSE=t1.ID_REFUSE																											/*������ � ID_CASE � ID_SERVICE � ������ ������. 
																																		��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. UPD:
																																		�� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
																																		(�������� � ������)
																																		*/
left join 
(
select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END from OPENquery(EIS, 'select * from CASES')															/*
																																		������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
																																		*/
group by ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END
) t2 on  t1.ID_CASE=t2.ID_CASE

																																		
left join 
(
select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE from OPENquery(EIS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_DEPT,ID_CASE,ILL_HISTORY from OPENquery(EIS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									/*
																																		� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
																																		������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
																																		� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
																																		*/
left join 
(
select * from OPENquery(EIS, 'select * from VMU_MU_DEPTS')
) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT																					/*
																																		��� ��� ������� - �������� ���������.
																																		*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 
) t


select * from #t_eis

order by DEPT_NAME,ILL_HIStory,flag
drop table #t_eis