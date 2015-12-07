declare @bd date
declare @ed date
set @bd = '01.08.2015'
set @ed = '31.08.2015'

															--����������� ��������� �� � ��
															
select ILL_HISTORY,ID_CASE, YEAR(DATE_END) data,DATE_END, sumib, kolIB,kolsly4,1 flag,ID_CASE_CAST 
into #t_eis_s 
from 
(
select ILL_HISTORY,ID_CASE,DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4, ID_CASE_CAST  from(
select ILL_HISTORY,t3.ID_CASE, t3.DATE_END, sum(service_cost) cost, COUNT(*) kol,ID_CASE_CAST from OPENquery(EISS, 'select * from case_services_accounts ') t
left join 
(
select * from OPENquery(EISS, 'select * from CASE_SERVICES') 
) t1 on  t.ID_ACCOUNT=t1.ID_ACCOUNT
left join
(
select * from OPENquery(EISS, 'select * from CASES')
) t3 on t1.ID_CASE=t3.ID_CASE

where account_date between @bd and @ed and ID_CASE_CAST<>1
group by ILL_HISTORY,t3.ID_CASE,t3.DATE_END,ID_CASE_CAST
) t
group by ILL_HISTORY, ID_CASE,DATE_END,ID_CASE_CAST
) t
--������ ��������� �� � ��
insert into #t_eis_s 
select  ILLH,ID_CASE, YEAR(data) data, data, sum(cost), 1 kolib ,COUNT(*) kolsly4,-1 flag,Case_cast
from
(
select  
case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end data,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														
case when t2.ID_CASE_CAST IS NULL then t22.ID_CASE_CAST else t2.ID_CASE_CAST end Case_cast,
/*
� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
*/																																		
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
/*������ � ID_CASE � ID_SERVICE � ������ ������. 
��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. 
UPD: �� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
(�������� � ������)
*/
left join 
(
select ID_CASE,ILL_HISTORY, DATE_END,ID_CASE_CAST from OPENquery(EISS, 'select * from CASES')												
group by  ID_CASE, ILL_HISTORY, DATE_END,ID_CASE_CAST /*�����������??? ������ �� �������� �����*/
) t2 on  t1.ID_CASE=t2.ID_CASE
/*
������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
*/
left join 
(
select t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_END,t1.ID_CASE_CAST from OPENquery(EISS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_CASE,ILL_HISTORY,DATE_END,ID_CASE_CAST from OPENquery(EISS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									
/*
� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 and (t2.ID_CASE_CAST<>1 or t22.ID_CASE_CAST<>1)
/*
�� ID_CASE_CAST ��������� ������������ ���-��� �� ������� ������������ �� � ��. 1 - ��� �����������. ���������� � ���� VMU_CASE_CAST
*/	
) t
group by ILLH,ID_CASE,data,Case_cast
/*
����� ������� � ������� #t_eis_s �������� ������ ������ �� �� � ��
*/

																					--����������� ��������� ��� � ���
																					
select ILL_HISTORY,ID_CASE, YEAR(DATE_END) data,DATE_END, sumib, kolIB,kolsly4,1 flag,ID_CASE_CAST,docname
into #t_eis_s_mrt 
from 
(
select  ILL_HISTORY,ID_CASE,DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4, ID_CASE_CAST,docname  from(
select ILL_HISTORY,t3.ID_CASE, t3.DATE_END, sum(service_cost) cost, COUNT(*) kol,ID_CASE_CAST,SURNAME+' '+NAME+' '+SECOND_NAME docname from OPENquery(EISS, 'select * from case_services_accounts ') t
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
select * from OPENquery(EISS, 'select * from VMU_DOCTORS')
)t4 on t3.ID_DOCTOR=t4.ID_DOCTOR
where account_date between @bd and @ed and ID_CASE_CAST=1
group by ILL_HISTORY,t3.ID_CASE,t3.DATE_END,ID_CASE_CAST,SURNAME,NAME,SECOND_NAME
) t
group by ILL_HISTORY, ID_CASE,DATE_END,ID_CASE_CAST,docname
) t
--������ ��������� ��� � ���
insert into #t_eis_s_mrt 
select  ILLH,ID_CASE, YEAR(data) data, data, sum(cost), 1 kolib ,COUNT(*) kolsly4,-1 flag,Case_cast,docname
from
(
select  
case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end data,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														
case when t2.ID_CASE_CAST IS NULL then t22.ID_CASE_CAST else t2.ID_CASE_CAST end Case_cast,
case when t4.docname IS NULL then t22.docname else t4.docname end docname,
/*
� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
*/																																		
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
/*������ � ID_CASE � ID_SERVICE � ������ ������. 
��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. 
UPD: �� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
(�������� � ������)
*/
left join 
(
select ID_CASE,ILL_HISTORY, DATE_END,ID_CASE_CAST,ID_DOCTOR from OPENquery(EISS, 'select * from CASES')												
group by  ID_CASE, ILL_HISTORY, DATE_END,ID_CASE_CAST,ID_DOCTOR /*�����������??? ������ �� �������� �����*/
) t2 on  t1.ID_CASE=t2.ID_CASE
left join
(
select ID_DOCTOR,SURNAME+' '+NAME+' '+SECOND_NAME docname from OPENquery(EISS, 'select * from VMU_DOCTORS')
)t4 on t2.ID_DOCTOR=t4.ID_DOCTOR
/*
������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
*/
left join 
(
select t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_END,t1.ID_CASE_CAST,docname from OPENquery(EISS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_CASE,ILL_HISTORY,DATE_END,ID_CASE_CAST,ID_DOCTOR from OPENquery(EISS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
	left join
	(
	select ID_DOCTOR,SURNAME+' '+NAME+' '+SECOND_NAME docname from OPENquery(EISS, 'select * from VMU_DOCTORS')
	)t4 on t1.ID_DOCTOR=t4.ID_DOCTOR
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									
/*
� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 and (t2.ID_CASE_CAST=1 or t22.ID_CASE_CAST=1)
/*
�� ID_CASE_CAST ��������� ������������ ���-��� �� ������� ������������ �� � ��. 1 - ��� �����������. ���������� � ���� VMU_CASE_CAST
*/	
) t
group by ILLH,ID_CASE,data,Case_cast,docname
/*
����� ������� � ������� #t_eis_s_mrt �������� ������ ������ �� ����������� ��� � ���
*/
/*
����� ������ �� ��� ��������� �� 2 �������� ����� ���� ������� ����� ������ ������ �� �����
*/

																	--����������� �����������
																	
select ILL_HISTORY,ID_CASE, YEAR(DATE_END) data,DATE_END,sumib,kolIB,kolsly4,1 flag ,ID_CASE_CAST,surname,name,second_name
into #t_eis_p
from 
(
select  ILL_HISTORY,ID_CASE, DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4,ID_CASE_CAST,surname,name,second_name  from(
select ILL_HISTORY,t3.ID_CASE,t3.DATE_END, sum(service_cost) cost, COUNT(*) kol, ID_CASE_CAST,surname,name,second_name from OPENquery(EIS, 'select * from case_services_accounts ') t
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
select * from OPENquery(EIS, 'select * from VMU_DOCTORS')
)t4 on t3.ID_DOCTOR=t4.ID_DOCTOR
where account_date between @bd and @ed
group by ILL_HISTORY,t3.ID_CASE,t3.DATE_END,ID_CASE_CAST,surname,name,second_name
) t
group by  ILL_HISTORY, ID_CASE, DATE_END,ID_CASE_CAST,surname,name,second_name
) t
--������ �����������

insert into #t_eis_p select ILLH,ID_CASE, YEAR(DATE_END), DATE_END,cost,1 kolib,1 kolsly4,-1 flag,ID_CASE_CAST,surname,name,second_name from
(
select t2.DATE_END,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														
case when t2.ID_CASE_CAST IS NULL then t22.ID_CASE_CAST else t2.ID_CASE_CAST end ID_CASE_CAST,
case when t4.surname IS NULL then t22.surname else t4.surname end surname,
case when t4.name IS NULL then t22.name else t4.name end name,
case when t4.second_name IS NULL then t22.second_name else t4.second_name end second_name,
/*
� ������� � �������� ��������� �� ��� �������� ID_CASE � ID_SERVICE, 
� �� ��� ����� ����� ILL_HISTORY �� ������ ������, ������� ��� ����, 
����� ������ NULL� � ���������� ��� ���� � ILL_HISTORY
*/
SUMM_REFUSE cost 
from OPENquery(EIS,'select * from REFUSES') t																							
/*
ACT_DATE  ��� ���� ��� � ���, � ReFUSE_DATE ��� ���� ��. 
ACT_MODE �� ����, ��� �� ���� 0, �� � ���� ������ �� �����, �������� ������.
���� - ID_REFUSE
*/
left join
(
select * from OPENquery(EIS, 'select * from REFUSES_OBJ ')																				
)t1 on t.ID_REFUSE=t1.ID_REFUSE																											
/*
������ � ID_CASE � ID_SERVICE � ������ ������. 
��� ���� ������� ������. �� ���� ����������� �� ��� ��� � ����� ������. 
UPD: �� �����������, �� ������� ���� � ����� ������ �� �������, ����� ������ ����� ������ ��� ��������� �� ����.
(�������� � ������)
*/
left join 
(
select ID_CASE,ILL_HISTORY,DATE_END,ID_CASE_CAST,ID_DOCTOR from OPENquery(EIS, 'select * from CASES')															
--group by ID_CASE,ILL_HISTORY,DATE_END,ID_CASE_CAST
) t2 on  t1.ID_CASE=t2.ID_CASE
/*
������ � ������� ������� �������. ������ �� ID_CASE ����� ����� �� � ������.
*/
left join 
(
select t1.ID_CASE,ILL_HISTORY,ID_SERVICE,ID_CASE_CAST,surname,name,second_name from OPENquery(EIS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_CASE,ILL_HISTORY,ID_CASE_CAST,ID_DOCTOR from OPENquery(EIS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
	left join
	(
	select * from OPENquery(EIS, 'select * from VMU_DOCTORS')
	)t4 on t1.ID_DOCTOR=t4.ID_DOCTOR
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									
/*
� ������� � �������� REFUSES_OBJ �� � ���� �������� ���� ID_CASE, �� � ��� ���� ID_SERVICE.
������� ����� ������� CASE_SERVICES, ��� ���� ������������ ����� ID_SERVICE � ID_CASE(from CASES)
� ������� � ��� CASES �� ��������� ����� ����� �� -> profit
*/
left join
	(
	select * from OPENquery(EIS, 'select * from VMU_DOCTORS')
	)t4 on t2.ID_DOCTOR=t4.ID_DOCTOR																		
/*
����� ��������� ����������� ������ � ����, ���� ������� �����
*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 
) t

/*
����� �� ���� ��� ������ (������������ � ����������) �� ���������� �������. ���������� flag=-1 ������������ flag=1
*/

/*
�� ��. ��������� �� �� ���� � �� �� �����. ��������� � ������� �� �����, ��������� �� ����
*/
select ISNULL(ctxtOtd,'������ ���������� ��� � ����') otd,ILL_HISTORY, sumib, flag,DOCUNID
into #t_eis_kmis_s
from #t_eis_s eis
left join IskStat2.dbo.istortable ib on 
((ILL_HISTORY not like '%��%' and REPLACE(eis.ILL_HISTORY,'-',' ')=ib.txtNumberIB collate Cyrillic_General_CI_AS) or (eis.ILL_HISTORY=ib.txtNumberIB collate Cyrillic_General_CI_AS))
and eis.data=YEAR(ib.datDateVipis)

/*������� ����������� ������ ��� ����. ��������� ���*/
select t_all.otd, ROUND(sumall/sumv,2) koeff_eis_s 
into #t_eis_koeff_s
from
(
select Otd,sum(sumib*flag) sumv from #t_eis_kmis_s where flag=1
group by Otd
) t_vyst
left join
(
select Otd,sum(sumib*flag) sumall from #t_eis_kmis_s
group by Otd
)t_all on t_vyst.otd=t_all.otd

/*������� � �� ����� � ���� � DOCUNID�� �� ������� �����, �� �������� ����� ����� ������ � �������*/
select otd,ILL_HISTORY, (sumib*koeff_eis_s) sumibk, flag,DOCUNID
into #t_eis_kmis_s_ib
from #t_eis_s eis
left join IskStat2.dbo.istortable ib on 
((ILL_HISTORY not like '%��%' and REPLACE(eis.ILL_HISTORY,'-',' ')=ib.txtNumberIB collate Cyrillic_General_CI_AS) or (eis.ILL_HISTORY=ib.txtNumberIB collate Cyrillic_General_CI_AS))
and eis.data=YEAR(ib.datDateVipis)
left join #t_eis_koeff_s  eis_k on isnull(ib.ctxtotd,'������ ���������� ��� � ����')=eis_k.otd
where flag=1
order by 2


/*������ � ������� �� �� ����� �� �������� �� ��.*/
select ctxtOtd,ctxtPayDoctor2,Test,DTXTNameILL,datDateVizit,case when IssKol>100 then 1 else IssKol end isskol,case when kod2='�25.30.001.001' then price else isnull(PLH_Price,price)end price,
case when CRFromFLD IN (select distinct DocUNID from #t_eis_kmis_s_ib) then CRFromFLD else CRFromD end num 
into #t_kmis_usl_s
from 
(select isnull(IskStat2.dbo.Doctors.ctxtOtd,'��������� �� �������') ctxtotd,
case when ctxtPayDoctor2 IS null then '����������� �� ������' when ctxtPayDoctor2='' then '����������� �� ������' else ctxtPayDoctor2 end ctxtPayDoctor2,
Test,DTXTNameILL,IskStat2.dbo.PatientServices.datDateVizit,
IssKol,kod2,CRFromD,CRFromFLD,Price 
from IskStat2.dbo.PatientServices 
left join IskStat2.dbo.Doctors on IskStat2.dbo.PatientServices.prMyDoctorCodeR2=IskStat2.dbo.Doctors.Name and prMyDoctorCodeR2<>''
where (NaznStatus=2 or NaznStatus=3) and PayType=1 and 
(CRFromD in (select distinct DocUNID from #t_eis_kmis_s_ib) or CRFromFLD in (select distinct DocUNID from #t_eis_kmis_s_ib)) /*(������ ��������� � ���)*/
) ps
left join
(
select MSR_UsrCode,PLH_Price from
(
select MSR_UsrCode,MAX(PLH_Code) code from finance.dbo.medservice m 
			inner join finance.dbo.pricehistory p
				on MSR_Delete!=1 and PLH_Fixed = 1 and MSR_Code = PLH_MSR_Code 
					group by MSR_UsrCode
					) t
					left join finance.dbo.pricehistory p on t.code=p.PLH_Code
			
) prices on ps.kod2=prices.MSR_UsrCode order by DTXTNameILL
insert into #t_kmis_usl_s
select 
				ctxtOtd collate Cyrillic_General_CI_AS,EXCECUROR_NAME collate Cyrillic_General_CI_AS,ANALIS_NAME collate Cyrillic_General_CI_AS, 
				name collate Cyrillic_General_CI_AS,DATE ,1 isskol,sum(cost)  ,
				Parent_Doc_ID collate Cyrillic_General_CI_AS
			from 
				(select 
						distinct o.ID, i.name anname, i.kod,  i.cost,
						 o.Parent_Doc_ID ,o.name,o.ctxtotd,o.EXCECUROR_NAME,o.DATE,o.ANALIS_NUM,o.ANALIS_NAME
					from 
						(select 
						FAM + ' ' + IM + ' ' + OT + ' (' + DR + ')' name, EXCECUROR_NAME, '�������-��������������� �����������' ctxtotd, ANALIS_NAME,ANALIS_NUM,ID,date,Parent_Doc_ID 
						from 
							Laboratory3.dbo.ORDERS 
						where 
							ResultStatus>=0 and  (HasBrokenLink is null or HasBrokenLink=0) --and date between '01.01.2015' and '31.10.2015' 
							
							and PayTypeCode='1' and right(Parent_Doc_ID,16) collate Cyrillic_General_CI_AS in  (select distinct right(DOCUNID,16) from #t_eis_kmis_s_ib)
						) o 
				left join 
					Laboratory3.dbo.ANALIS a 
						on o.ANALIS_NUM=a.NUM and a.isComplex=1 
				left join 
					Laboratory3.dbo.RESULTS r 
						on o.ID=r.USER_ID and a.NUM=r.ANALIS_NUM 
--��������� ������� ��� ����������� ����, ���� � ���(����� � ���������)
				left join 
					service.dbo.AnalisInfo i 
						on i.Name=r.PARAM_UNDER_GROUP or i.Name=o.ANALIS_NAME
				) l 
group by ctxtOtd,EXCECUROR_NAME,ANALIS_NAME,name,DATE,Parent_Doc_ID

/*�������� �������. ��������� ����� � �������� �������� �� ����������� ���������� �������� ��������� �� � ���� �� ��������� �� � �����.*/
select 
case when ctxtotd is null then otd else ctxtotd end ctxtotd,
ISNULL(ctxtpaydoctor2,'�� ����������')ctxtpaydoctor2,ISNULL(Test,'�� ����������')Test,ISNULL(dtxtnameill,'�� ����������')dtxtnameill,ISNULL(datdatevizit,'')datdatevizit,ISNULL(isskol,'1')isskol,
case when price*koef is null then sumibk else price*koef end cost,koef from #t_kmis_usl_s u
full join
(
select otd,ILL_HISTORY,sumibk,flag,DOCUNID,isnull(uslcost,1) summauslug,count,numb, sumibk/isnull(uslcost,1) koef   from #t_eis_kmis_s_ib ib
left join 
(
select 
SUM(price*isskol)uslcost,SUM(isskol) count,RIGHT(num,16) numb
from #t_kmis_usl_s 
group by RIGHT(num,16)
) u on right(ib.DOCUNID,16)=u.numb
) k on right(u.num,16)=k.numb
--order by koef, dtxtnameill
union all
/*���. �������� �������.*/
select ctxtOtd,UserName ctxtpaydoctor2,'���-���-���' Test,'��� �������' dtxtnameill,/*convert(varchar,@bd) +'-'+convert(varchar,@ed)*/'' datDateVizit,1 isskol,sumv cost,1 koef from
(select  rtrim(SUBSTRING(docname,1,CHARINDEX(' ',docname))) docname,sum(sumib*flag) sumv from #t_eis_s_mrt group by docname) m
left join
(select ctxtotd,rtrim(SUBSTRING(UserName,1,CHARINDEX(' ',UserName))) docname,UserName from IskStat2.dbo.Doctors) d on m.docname = d.docname collate Cyrillic_General_CI_AS
union all

/*�������� �������. ���������� ���� � �����. ���� ������ ������������� ��������� ��� �����, ��� �������� ������ � �� ���������*/
--��� ��� ���������, �� ����� ������ ������������ �� ������ � �� ��������

select ISNULL(d.ctxtOtd,'����������� ����������������') ctxtotd,ISNULL(CTXTPAYDOCTOR,surname+' '+ep.name+' '+second_name) ctxtpaydoctor2,
case when Kod4 is null then '������ �� �������'
when Kod4 = ' ' then '������ �� �������' else Kod4 end test,
ISNULL(DTXTNAMEILL,'����������� �������') dtxtnameill,
DATE_END datDateVizit,1 isskol,
sumib*flag cost, 1 koef
from #t_eis_p ep				
left join 
(
select txtNumberAk num,
SUBSTRING(ctxtPayDoctor,0,CHARINDEX(' ',ctxtPayDoctor)) docname,
ctxtOtd,Kod4,Kod3_,DTXTNAMEILL,DATDATEVIZIT,
ctxtPayDoctor,prMyDoctorCodeR,
COUNT(*) kolvo
from IskStat2.dbo.StatTal4 
--where DATDATEVIZIT>='01.07.2015'
group by txtNumberAk,ctxtPayDoctor,ctxtOtd,Kod4,Kod3_,DTXTNAMEILL,DATDATEVIZIT,prMyDoctorCodeR
) ps on ep.ILL_HISTORY=ps.num collate Cyrillic_General_CI_AS and ep.date_end=CAST(ps.datDateVizit as date) and ep.surname collate Cyrillic_General_CI_AS =ps.docname
left join
IskStat2.dbo.Doctors d on ps.prMyDoctorCodeR=d.Name and d.Name<>''
--order by datDateVizit
drop table #t_eis_kmis_s,#t_eis_kmis_s_ib,#t_eis_koeff_s,#t_eis_p,#t_eis_s,#t_eis_s_mrt,#t_kmis_usl_s