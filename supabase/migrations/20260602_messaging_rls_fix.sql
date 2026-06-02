-- Étudiants : accès uniquement à leur propre conversation et ses messages
CREATE POLICY IF NOT EXISTS "student_own_conversation" ON conversations
  FOR ALL TO authenticated
  USING (student_profile_id = auth.uid());

CREATE POLICY IF NOT EXISTS "student_own_messages" ON messages
  FOR ALL TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM conversations WHERE student_profile_id = auth.uid()
    )
  );
