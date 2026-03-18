C     Test MED Fortran file operations:
C       - Library version query (mlbnuv)
C       - File create/open/close (mfiope, mficlo)
C       - Comment write/read (mficow, mficor)
C
C     These are core operations used by code-aster's as_mfiope/as_mficlo
C
      program test_file_ops

      implicit none
      include 'med.hf'

      integer*8 cret
      integer*8 fid
      character*200 des
      character*200 des_read
      integer*8 major, minor, rel

C     Get MED library version
      call mlbnuv(major, minor, rel, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mlbnuv failed'
         call exit(1)
      endif
      print *, 'MED library version:', major, minor, rel

C     Create a new MED file
      call mfiope(fid, 'test_fops.med', MED_ACC_RDWR, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope create failed'
         call exit(1)
      endif

C     Write a file comment
      des = 'Test file created by Fortran API test'
      call mficow(fid, des, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficow failed'
         call exit(1)
      endif

C     Close the file
      call mficlo(fid, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficlo failed'
         call exit(1)
      endif

C     Re-open in read-only mode
      call mfiope(fid, 'test_fops.med', MED_ACC_RDONLY, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope read-only failed'
         call exit(1)
      endif

C     Read the comment back
      call mficor(fid, des_read, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficor failed'
         call exit(1)
      endif
      print *, 'Comment: ', trim(des_read)

C     Close the file
      call mficlo(fid, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficlo final close failed'
         call exit(1)
      endif

      print *, 'test_file_ops: PASSED'

      end
