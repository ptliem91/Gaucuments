CREATE OR REPLACE PACKAGE "TR_MC_DATA_ERROR_CHECK" AS
-- *****************************************************************************
--		$Id: PACKAGE.TR_MC_DATA_ERROR_CHECK.pls 11077 2013-08-19 07:11:45Z hungmh $
--		�ڋq��				�F�O�J�Y�Ɗ������
--		�V�X�e����			�F�k�Q�v���W�F�N�g
--		�T�u�V�X�e����			�F190 ���Y�Ǘ�
--		�Ǝ햼�i���ƕ����j	    �F���̌^�@�O���[�v���
--		All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

	-- 190_20_10_02 ���ޗ������c�G���[�`�F�b�N
	FUNCTION CHECK_ORDER_REMAIN(
		I_JOB_ID					IN	NUMBER
		,I_EXEC_JOB_ID				IN	VARCHAR2
		,I_TOP_DEPT_NO				IN	VARCHAR2
	) RETURN NUMBER;

    -- 190_20_11_02 �d�����уf�[�^�G���[�`�F�b�N
    FUNCTION CHECK_PURCHASE_ACTUAL(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

    -- 190_20_12_02 ���ޗ��o��o�f�[�^�G���[�`�F�b�N
    FUNCTION CHECK_MATERIAL_TAKE_OUT(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

    -- 190_20_13_02 �݌Ɏc���f�[�^�G���[�`�F�b�N
    FUNCTION CHECK_INVENT_BALANCE_AMO(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

    -- 190_20_14_02 ���i�o�׃f�[�^�G���[�`�F�b�N
    FUNCTION CHECK_GOODS_OUT_GO(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

    -- 190_20_16_02 ���������f�[�^�G���[�`�F�b�N
    FUNCTION CHECK_PROD_COST(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

    -- 190_20_17_02 ���i�}�X�^�f�[�^�G���[�`�F�b�N
    FUNCTION CHECK_GOODS_MAST(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER;

	-- 190_20_19_02   �d�|�����f�[�^�G���[�`�F�b�N
	FUNCTION CHECK_IN_PROCESS_COST(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
	)RETURN NUMBER;
	
	-- 190_20_21_02   ���i�݌ɕ\�������уf�[�^�G���[�`�F�b�N
	FUNCTION CHECK_IN_PROCESS_COST_ACT(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
	)RETURN NUMBER;

END "TR_MC_DATA_ERROR_CHECK";
