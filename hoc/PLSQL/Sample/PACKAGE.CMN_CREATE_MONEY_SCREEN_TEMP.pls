PACKAGE "CMN_CREATE_MONEY_SCREEN_TEMP" AS
-- *****************************************************************************
--      $Id: PACKAGE.CMN_CREATE_MONEY_SCREEN_TEMP.pls 3553 2008-05-29 14:23:30Z a.hira $
--      �ڋq��            �F�O�J�Y�Ɗ������
--      �V�X�e����        �F�k�Q�v���W�F�N�g
--      �Ǝ햼�i���ƕ����j�F����
--      �v���O������      �F�����ꗗ�Ɖ�TEMP�쐬
--      All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

    -- �����ꗗ�Ɖ�TEMP�쐬
    PROCEDURE CREATE_MONEY_SCREEN_TEMP(
         I_TOP_DEPT_NO          IN	VARCHAR2	-- 1.�ŏ�ʕ���ԍ��i�K�{�j
        ,I_MONEY_DATE_S         IN	VARCHAR2	-- 2.�J�n�������t�i�K�{�j
        ,I_MONEY_DATE_E         IN	VARCHAR2	-- 3.�I���������t�i�K�{�j
        ,I_DUE_DEPT_NO          IN	VARCHAR2	-- 4.�S������ԍ�
        ,I_DUE_EMP_CODE         IN	VARCHAR2	-- 5.�S���Ј��R�[�h
 		,I_INVOICE_TO_NO		IN	VARCHAR2	-- 6.������ԍ�
		,I_INVOICE_TO_ACCO_NO	IN	VARCHAR2	-- 7.����������ԍ�
		,I_ACCOUNT_SUBJECT_CODE	IN	VARCHAR2	-- 8.����ȖڃR�[�h
		,I_DENOMINATION_TYPE	IN	VARCHAR2	-- 9.����敪
		,I_ADD_UP_FLG			IN	VARCHAR2	--10.���������t���O
								-- (TRUE:������ FALSE:������ NULL:�����ɂ��Ȃ�)
		,I_PARTNER_UNASSIGN_FLG	IN	VARCHAR2	--11.����斢���t���̂݃t���O
								-- (TRUE:����斢���t���̂� FALSE:�����ɂ��Ȃ�)
        ,I_DEPT_UNASSIGN_FLG     IN	VARCHAR2	--12.���喢���t���̂݃t���O
                                -- (TRUE:���喢���t���̂� FALSE:�����ɂ��Ȃ�)
        
        
    );
END "CMN_CREATE_MONEY_SCREEN_TEMP";

