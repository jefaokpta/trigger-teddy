DELIMITER $$
CREATE TRIGGER `ajustTransfer` AFTER INSERT ON `cdr` FOR EACH ROW
BEGIN
declare _numcalls int;
declare _id int;
declare _ccost int;
declare _billsec_custom int;
declare _uniq char(50);
declare _disp char(20);

    if new.channel != 'Console/dsp' then
      if new.lastapp = 'NoOp' and new.accountcode >= 2 and new.billsec > 0 then
        if new.dcontext = 'dialPeer' then           
          update relcalls set duration=(duration+new.duration),billsec=(billsec+new.billsec),accountcode=new.accountcode,
            price=(select tarifadorVip((billsec+new.billsec),new.accountcode,substr(new.lastdata,1,3)))
              where calldate BETWEEN concat(substr(now(),1,10),' 00:00:00') and now()
                and company_id = substr(new.lastdata,1,3) and channel=new.dstchannel;
        elseif new.dcontext = 'dialRoute' then           
          update relcalls set duration=(duration+new.duration),billsec=(billsec+new.billsec),
            price=(select tarifadorVip((billsec+new.billsec),accountcode,substr(new.lastdata,1,3)))
              where calldate BETWEEN concat(substr(now(),1,10),' 00:00:00') and now()
                and company_id = substr(new.lastdata,1,3) and channel=new.channel;
        elseif new.dcontext = 'dialRoute' then
            update relcalls set duration=new.duration,billsec=new.billsec,accountcode=new.accountcode,
                price=(select tarifadorVip(new.billsec,new.accountcode,new.company_id))
                  where calldate BETWEEN concat(substr(now(),1,10),' 00:00:00') and now()
                    and channel=new.dstchannel;
        end if;
      elseif substr(new.dcontext,1,6) = 'TRANSF' and new.accountcode >= 2 and new.billsec > 0 then 
        update relcalls set duration=(duration+new.duration),billsec=(billsec+new.billsec),
            price=(select tarifadorVip((billsec+new.billsec),accountcode,substr(new.dcontext,8)))
              where calldate BETWEEN concat(substr(now(),1,10),' 00:00:00') and now()
                and company_id = substr(new.dcontext,8) and channel=new.dstchannel;
        
      else
      
        if new.accountcode = 1.51 or new.accountcode = 1.52 or new.accountcode = 1.53 then
            select uniqueid,disposition,id,accountcode into _uniq,_disp,_id,_ccost from relcalls where calldate BETWEEN concat(substr(now(),1,10),' 00:00:00') and now()
                and uniqueid=new.uniqueid order by uniqueid desc limit 1;
            if _uniq IS NULL then 
              insert into relcalls (calldate,src,srcfinal,dstfinal,disposition,
                duration,billsec,accountcode,uniqueid,channel,price,userfield,cidade,estado,company_id,trunk_id)
                  values(new.calldate,new.src,new.srcfinal,new.dstfinal,new.disposition,
                    new.duration,new.billsec,new.accountcode,new.uniqueid,new.dstchannel,
                      (select tarifadorVip(new.billsec,new.accountcode,new.company_id)),new.userfield,(select cidade(new.dstfinal)),(select estado(new.dstfinal)),new.company_id,new.trunk_id);

            else 
                  if new.billsec > 0 then
                    update relcalls set disposition='ANSWERED',duration=(duration+new.duration),billsec=(billsec+new.billsec),price=(select tarifadorVip((billsec+new.billsec),new.accountcode,new.company_id)) where id=_id;
                  end if;
            end if;
            
        else
            set _billsec_custom = new.billsec;
            if new.disposition = 'NO ANSWER' then 
              set _billsec_custom = 0;
            end if;
              insert into relcalls (calldate,src,srcfinal,dstfinal,disposition,
                duration,billsec,accountcode,uniqueid,channel,price,userfield,cidade,estado,company_id,trunk_id)
                  values(new.calldate,new.src,new.srcfinal,new.dstfinal,new.disposition,
                    new.duration,_billsec_custom,new.accountcode,new.uniqueid,new.dstchannel,
                      (select tarifadorVip(_billsec_custom,new.accountcode,new.company_id)),new.userfield,(select cidade(new.dstfinal)),(select estado(new.dstfinal)),new.company_id,new.trunk_id);
        end if;
      end if;
    end if;
 END$$
DELIMITER ;